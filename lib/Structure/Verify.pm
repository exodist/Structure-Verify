package Structure::Verify;
use strict;
use warnings;

use Carp qw/croak/;

use Structure::Verify::Delta;
use Structure::Verify::Got;

our $VERSION = '0.001';

use Importer Importer => 'import';
our @EXPORT_OK = qw/build current_build run_checks/;

my @BUILDS;

sub current_build { @BUILDS ? $BUILDS[-1] : undef }

sub build {
    my %args = @_;

    my $builder = $args{builder};
    my $check   = $args{check};
    my $meta    = $args{meta};
    my $args    = $args{args};

    push @BUILDS => $check;
    my ($ok, $err);
    {
        local ($@, $?, $!);
        $ok = eval { $builder->($check, $meta, $args); 1 };
        $err = $@;
    }
    pop @BUILDS;

    die $err unless $ok;

    return $check;
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
