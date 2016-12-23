package Structure::Verify;
use strict;
use warnings;

use Carp qw/croak/;
use Structure::Verify::Util::Ref qw/rtype/;

use Structure::Verify::Delta;
use Structure::Verify::Meta;
use Structure::Verify::Got;

our $VERSION = '0.001';

use Importer Importer => 'import';
our @EXPORT_OK = qw{
    build current_build

    run_checks

    check checks end etc

    load_check    load_checks
    load_check_as load_checks_as
};

sub current_build {
    my $meta = Structure::Verify::Meta->new(scalar caller);
    $meta->current_build;
}

sub build {
    my ($make, $with) = @_;
    my $meta = Structure::Verify::Meta->new(scalar caller);

    my $class = $make =~ m/^\+(.*)$/ ? $1 : $meta->build_map->{$make};

    croak "Not sure how to build a '$make'"
        unless $class;

    my $check  = $class->new;
    my $builds = $meta->builds;

    push @$builds => $check;
    my ($ok, $err);
    {
        local ($@, $?, $!);
        $ok = eval { $check->build($with); 1 };
        $err = $@;
    }
    pop @$builds;

    die $err unless $ok;

    return $check;
}

sub check {
    my $check = pop;
    my $id = shift;

    my $meta = Structure::Verify::Meta->new(scalar caller);
    my $build = $meta->current_build or croak "No current build";

    return $build->add_check($id => $check)
        if defined $id;

    return $build->add_check($check);
}

my %CHECKS_REFS = (HASH => 1, ARRAY => 1);
sub checks {
    my $ref = shift;
    my $type = rtype($ref);

    croak "'checks' takes either a hashref or an arrayref"
        unless $CHECKS_REFS{$type};

    my $meta = Structure::Verify::Meta->new(scalar caller);
    my $build = $meta->current_build or croak "No current build";

    if ($type eq 'HASH') {
        $build->add_check($_ => $ref->{$_}) for keys %$ref;
    }
    elsif ($type eq 'ARRAY') {
        $build->add_check(@_) for @$ref;
    }
}

sub end {
    my $meta = Structure::Verify::Meta->new(scalar caller);
    my $build = $meta->current_build or croak "No current build";

    croak "Current build '$build' cannot be bounded"
        unless $build->can('set_bounded');

    $build->set_bounded(1);
}

sub etc {
    my $meta = Structure::Verify::Meta->new(scalar caller);
    my $build = $meta->current_build or croak "No current build";

    croak "Current build '$build' cannot be unbounded"
        unless $build->can('set_bounded');

    $build->set_bounded(0);
}

{
    no warnings 'once';
    *load_check    = \&load_checks;
    *load_check_as = \&load_checks_as;
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
    my $in_path = $params{path};

    my @todo  = ([$in_path || '', $want, Structure::Verify::Got->from_return($in)]);
    my $delta = Structure::Verify::Delta->new();
    my $pass  = 1;

    while (my $step = shift @todo) {
        my ($path, $check, $got) = @$step;

        $check = $convert->($check) if $convert;

        croak "$path: " . (defined($check) ? "'$check'" : "<undef>") . " is not a valid check"
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
