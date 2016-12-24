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

our $VERSION = '0.001';

$Carp::Internal{ (__PACKAGE__) }++;

use Importer Importer => 'import';
our @EXPORT_OK = qw{
    build current_build

    run_checks

    check checks end etc

    load_check      load_checks
    load_check_as   load_checks_as
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

    my $class = $make =~ m/^\+(.*)$/ ? $1 : $meta->build_map->{$make};

    croak "Not sure how to build a '$make'"
        unless $class;

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

    my $check  = $class->new(file => $file, lines => $lines, via_build => 1);
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

    return $check;
}

sub check($;$) {
    my $check = pop;
    my $id = shift;

    my $meta = Structure::Verify::Meta->new(scalar caller);
    my $build = $meta->current_build or croak "No current build";

    croak "Check '" . blessed($build) . "' does not support subchecks"
        unless $build->can('add_subcheck');

    return $build->add_subcheck($id => $check)
        if defined $id;

    return $build->add_subcheck($check);
}

my %CHECKS_REFS = (HASH => 1, ARRAY => 1);
sub checks($) {
    my $ref = shift;
    my $type = rtype($ref);

    croak "'checks' takes either a hashref or an arrayref"
        unless $CHECKS_REFS{$type};

    my $meta = Structure::Verify::Meta->new(scalar caller);
    my $build = $meta->current_build or croak "No current build";

    croak "Check '" . blessed($build) . "' does not support subchecks"
        unless $build->can('add_subcheck');

    if ($type eq 'HASH') {
        $build->add_subcheck($_ => $ref->{$_}) for keys %$ref;
    }
    elsif ($type eq 'ARRAY') {
        $build->add_subcheck($_) for @$ref;
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

{
    no warnings 'once';
    *load_check      = \&load_checks;
    *load_check_as   = \&load_checks_as;
}

sub load_checks {
    my $meta = Structure::Verify::Meta->new(scalar caller);
    $meta->load(@_);
}

sub load_checks_as {
    my $meta = Structure::Verify::Meta->new(scalar caller);
    $meta->load_as(@_);
}

sub run_checks {
    my ($in, $want, %params) = @_;

    my $convert = $params{convert};
    my $in_path = $params{path} || '';

    my @todo  = ([$in_path || '', $want, Structure::Verify::Got->from_return($in)]);
    my $delta = Structure::Verify::Delta->new();
    my $pass  = 1;

    while (my $step = shift @todo) {
        my ($path, $check, $got) = @$step;

        $check = $convert->($check) if $convert;

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
            );

            unless ($ok) {
                $pass = 0;
                next;
            }
        }

        unshift @todo => $check->subchecks($path, $got)
            if $check->can('subchecks');
    }

    return (1) if $pass;
    return (0, $delta);
}

1;
