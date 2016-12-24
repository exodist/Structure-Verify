package Structure::Verify::Check::Value;
use strict;
use warnings;

use Carp qw/croak/;
use Structure::Verify::Util::Ref qw/render_ref rtype/;

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

    if (my $type = rtype($value)) {
        my $refa = $type eq 'REGEXP' ? "$value" : render_ref($value);
        my $refb = "$value";

        my @cells;

        push @cells => Term::Table::Cell->new(
            value        => $refa,
            border_left  => '>',
            border_right => '<',
        );

        push @cells => Term::Table::Cell->new(
            value        => $refb,
            border_left  => '>',
            border_right => '<',
        ) if $refa ne $refb;

        return $cells[0] unless @cells > 1;
        return Term::Table::CellStack->new(cells => \@cells);
    }

    return Term::Table::Cell->new(
        value => "$value",
    );
}

1;
