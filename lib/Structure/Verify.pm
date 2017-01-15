package Structure::Verify;
use strict;
use warnings;

use Carp qw/croak/;
use Structure::Verify::Util::Ref qw/rtype/;
use Sub::Info qw/sub_info/;
use Scalar::Util qw/blessed/;

use Structure::Verify::Delta;
use Structure::Verify::Meta;
use Structure::Verify::Got;
use Structure::Verify::ProtoCheck;

our $VERSION = '0.001';

$Carp::Internal{ (__PACKAGE__) }++;

use Importer Importer => 'import';
our @EXPORT_OK = qw{
    build current_build

    run_checks

    check checks check_pair end etc
};

sub current_build() {
    my $meta = Structure::Verify::Meta->new(scalar caller);
    $meta->current_build;
}

sub build($$) {
    my @caller = caller(0);
    _build(\@caller, @_);
}

sub _build {
    my ($caller, $make, $with) = @_;

    my $meta = Structure::Verify::Meta->new($caller->[0]);

    my $class;
    if ($make =~ m/^\+(.*)$/) {
        $class = $1;
    }
    else {
        $class = 'Structure::Verify::Check::' . join '' => map { ucfirst(lc($_)) } split /_/, $make;
    }

    my $cfile = $class;
    $cfile =~ s{::}{/}g;
    $cfile .= '.pm';

    my $found;
    {
        local ($@, $?, $!);
        $found = $INC{$cfile} || eval { require $cfile; 1 } || $class->isa('Structure::Verify::Check');
    }

    croak "Not sure how to build a '$make'"
        unless $class && $found;

    my ($file, $lines);
    if (rtype($with) eq 'CODE') {
        my $info = sub_info($with);
        $file  = $info->{file};
        $lines = $info->{lines};
    }
    else {
        $file  = $caller->[1];
        $lines = [ $caller->[2] ];
    }

    my $check  = $class->new_build(file => $file, lines => $lines);
    my $builds = $meta->builds;

    push @$builds => $check;
    my ($ok, $err);
    {
        local ($@, $?, $!);
        $ok = eval { $check->build($with, $make); 1 };
        $err = $@;
    }
    pop @$builds;

    die $err unless $ok;

    $check->post_build();
    return $check;
}

sub _add_check {
    my $caller = shift;
    my $check  = shift;
    my ($id) = @_;

    my $meta = Structure::Verify::Meta->new($caller->[0]);
    my $build = $meta->current_build or croak "No current build";

    croak "Check '" . blessed($build) . "' does not support subchecks"
        unless $build->can('add_subcheck');

    $check = Structure::Verify::ProtoCheck->new(
        raw   => $check,
        file  => $caller->[1],
        lines => [$caller->[2]],
    ) unless blessed($check) && $check->isa('Structure::Verify::Check');

    return $build->add_subcheck($id => $check)
        if @_;

    return $build->add_subcheck($check);
}

sub check($;$) {
    my $check = pop;
    my ($id) = @_;
    my @caller = caller(0);

    return _add_check(\@caller, $check, $id)
        if @_;

    return _add_check(\@caller, $check);
}

sub check_pair($$) {
    my ($c1, $c2) = @_;

    my @caller = caller(0);

    _add_check(\@caller, $c1);
    _add_check(\@caller, $c2);

    return;
}

sub checks($) {
    my $ref = shift;
    my $type = rtype($ref);

    my @caller = caller(0);

    if ($type eq 'HASH') {
        _add_check(\@caller, $ref->{$_}, $_) for keys %$ref;
    }
    elsif ($type eq 'ARRAY') {
        _add_check(\@caller, $_) for @$ref;
    }
    else {
        croak "'checks' takes either a hashref or an arrayref";
    }
}

sub end() {
    my $meta = Structure::Verify::Meta->new(scalar caller);
    my $build = $meta->current_build or croak "No current build";

    croak "Current build '" . blessed($build) . "' cannot be bounded"
        unless $build->can('set_bounded');

    $build->set_bounded(1);
}

sub etc() {
    my $meta = Structure::Verify::Meta->new(scalar caller);
    my $build = $meta->current_build or croak "No current build";

    croak "Current build '" . blessed($build) . "' cannot be bounded"
        unless $build->can('set_bounded');

    $build->set_bounded(0);
}

sub run_checks {
    my ($in, $want, %params) = @_;

    my $convert  = $params{convert};
    my $in_path  = $params{path} || '';
    my $in_state = $params{state} || {};

    my @todo  = ([$in_path || '', $want, Structure::Verify::Got->from_verify_input($in), $in_state]);
    my $delta = Structure::Verify::Delta->new();
    my $pass  = 1;

    while (my $step = shift @todo) {
        my ($path, $check, $got, $state) = @$step;

        ($check, $state) = $convert->($check, $state) if $convert;

        croak(($path ? "$path: " : "") . (defined($check) ? "'$check'" : "<undef>") . " is not a valid check")
            unless $check && $check->isa('Structure::Verify::Check');

        unless ($check->verify($got)) {
            $pass = 0;
            $delta->add($path, $check, $got);
            next;
        }

        if ($check->can('complex_check')) {
            my $ok = $check->complex_check(
                path    => $path,
                got     => $got,
                delta   => $delta,
                convert => $convert,
                state   => $state,
            );

            unless ($ok) {
                $pass = 0;
                next;
            }
        }

        unshift @todo => map { push @{$_} => $state; $_ } $check->subchecks($path, $got)
            if $check->can('subchecks');
    }

    return (1) if $pass;
    return (0, $delta);
}

1;
