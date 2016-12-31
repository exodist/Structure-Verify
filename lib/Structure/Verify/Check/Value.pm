package Structure::Verify::Check::Value;
use strict;
use warnings;

use Carp qw/croak/;
use Structure::Verify::Util::Ref qw/render_ref rtype ref_cell/;

use parent 'Structure::Verify::Check';
use Structure::Verify::HashBase qw/-value/;

use Term::Table::Cell;
use Structure::Verify::Got;

sub verify {
    my $self = shift;
    my ($got) = @_;

    croak "verify() requires a 'Structure::Verify::Got' instance as the only argument"
        unless $got && $got->isa('Structure::Verify::Got');

    1;
}

sub build {
    my $self = shift;
    my ($with, $alias) = @_;

    my $type = rtype($with);

    return $self->{+VALUE} = $with
        if !$type || $type eq 'REGEXP';

    return $self->SUPER::build(@_);
}

sub cell {
    my $self = shift;

    my $value = $self->value;

    return Term::Table::Cell->new(
        value        => 'NOT DEFINED',
        border_left  => '>',
        border_right => '<',
    ) unless defined $value;

    return Term::Table::Cell->new(value => "$value")
        unless ref $value;

    return ref_cell($value);
}

1;
