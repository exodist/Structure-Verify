package Structure::Verify::Check::Compound;
use strict;
use warnings;

use parent 'Structure::Verify::Check';
use Structure::Verify::HashBase qw/-children -type/;

use Carp qw/croak/;
use Structure::Verify qw/run_checks/;

use Structure::Verify::Got;
use Term::Table::CellStack;

my %TYPES = (
    all  => 1,
    any  => 1,
    one  => 1,
    none => 1,
);

sub init {
    my $self = shift;

    croak "Valid types are: " . join(', ' => sort keys %TYPES)
        unless $TYPES{$self->{+TYPE}};
}

sub operator {
    my $self = shift;
    return uc($self->{TYPE});
}

sub verify { 1 }

sub cell {
    my $self = shift;

    return Term::Table::CellStack->new(
        cells => [map { $_->cell(@_) } @{$self->{+CHILDREN}}],
    );
}

sub complex_check {
    my $self   = shift;
    my %params = @_;

    my $type  = $self->{+TYPE};
    my $got   = $params{got};
    my $delta = $params{delta};

    my ($min, $count);
    if    ($type eq 'any')  { $min   = 1 }
    elsif ($type eq 'one')  { $count = 1 }
    elsif ($type eq 'none') { $count = 0 }
    elsif ($type eq 'all')  { $count = @{$self->{+CHILDREN}} }

    my %matched;
    for my $check (@{$self->{+CHILDREN}}) {
        my ($ok) = run_checks($got, $check, %params);
        next unless $ok;

        $matched{$check} = 1;

        return if $min && $min <= keys %matched;
    }

    return 1 if $count == keys %matched;

    $delta->add($params{path}, $_, $got, $matched{$_} ? ('*' => '*') : ()) for @{$self->{+CHILDREN}};

    return 0;
}

1;
