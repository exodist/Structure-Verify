package Structure::Verify::Check::One;
use strict;
use warnings;

use parent 'Structure::Verify::Check';
use Structure::Verify::HashBase qw/-children/;

use Carp qw/croak/;
use Structure::Verify qw/run_checks/;
use Structure::Verify::Util::Ref qw/rtype/;

use Structure::Verify::Got;
use Term::Table::CellStack;

sub operator { 'ONE' }
sub verify { 1 }

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

    return Term::Table::CellStack->new(
        cells => [map { $_->cell(@_) } @{$self->{+CHILDREN}}],
    );
}

sub complex_check {
    my $self   = shift;
    my %params = @_;

    my $got   = $params{got};
    my $delta = $params{delta};

    my %matched;
    for my $check (@{$self->{+CHILDREN}}) {
        my ($ok) = run_checks($got, $check, %params);
        $matched{$check} = $ok;
    }

    return 1 if 1 == keys %matched;

    $delta->add($params{path}, $_, $got, $matched{$_} ? ('*' => '*') : ()) for @{$self->{+CHILDREN}};

    return 0;
}

sub add_subcheck {
    my $self = shift;
    my ($check, $extra) = @_;

    croak "Too many arguments" if $extra;

    push @{$self->{+CHILDREN}} => $check;
}

1;
