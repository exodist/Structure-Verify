package Structure::Verify::Check::Any;
use strict;
use warnings;

use Structure::Verify::CheckMaker;
use Structure::Verify::HashBase qw/-children/;

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use Structure::Verify qw/run_checks/;
use Structure::Verify::Util::Ref qw/rtype ref_cell/;

use Structure::Verify::Got;
use Term::Table::Cell;

sub operator { 'ANY' }

sub build {
    my $self = shift;
    my ($with, $alias) = @_;

    if (rtype($with) eq 'ARRAY') {
        push @{$self->{+CHILDREN}} => @$with;
        return;
    }

    return $self->SUPER::build(@_);
}

sub cell {
    my $self = shift;

    return Term::Table::Cell->new(
        value        => "...",
        border_left  => '>',
        border_right => '<',
    );
}

sub negate {
    my $self = shift;
    require Structure::Verify::Check::None;
    return Structure::Verify::Check::None->new(children => [@{$self->children}]);
}

sub verify_complex {
    my $self   = shift;
    my %params = @_;

    my $got     = $params{got};
    my $delta   = $params{delta};
    my $convert = $params{convert};
    my $state   = $params{state};

    my @checks;
    for my $check (@{$self->{+CHILDREN}}) {
        my ($c, $s) = $convert ? $convert->($check, $state) : ($check, $state);
        my ($ok) = run_checks($got, $c, %params, state => $s);
        return 1 if $ok;
        push @checks => ($c, ' ');
    }

    $delta->add($params{path}, [$self => ' ', @checks], $got);

    return 0;
}

sub add_subcheck {
    my $self = shift;
    my ($check, $extra) = @_;

    croak "Too many arguments" if $extra;

    push @{$self->{+CHILDREN}} => $check;
}

1;
