package Structure::Verify::Check;
use strict;
use warnings;

use Carp qw/croak carp/;
use Scalar::Util qw/blessed/;
use Structure::Verify::Util::Ref qw/rtype ref_cell/;

use Structure::Verify::HashBase qw/-_lines -file -via_build/;

use Term::Table::Cell;
use Structure::Verify::Meta;

sub SHOW_ADDRESS { 0 }

sub init {
    my $self = shift;

    $self->{+_LINES} ||= delete $self->{lines};

    unless ($self->{+_LINES} && $self->{+FILE}) {
        my @caller = initial_trace(
            __PACKAGE__,
            'Structure::Verify::HashBase',
        ) or return;

        $self->{+FILE}   ||= $caller[1];
        $self->{+_LINES} ||= [$caller[2]];
    }
}

sub initial_trace {
    my @exclude = @_;
    my $level = 1;

    FRAME: while (my @caller = caller($level++)) {
        for (@exclude) {
            next FRAME if $caller[0]->isa($_);
        }

        return @caller;
    }

    return;
}

sub build {
    my $self = shift;
    my ($with, $alias) = @_;

    my $type = rtype($with);

    return $with->($self, $alias)
        if $type eq 'CODE';

    return $self->{$self->VALUE} = $with
        if $self->can('value') && (!$type || $type eq 'REGEXP');

    my $class = blessed($self);
    croak "'$class' does not know how to build with '$with'"
}

sub operator { croak blessed($_[0]) . " does not implement operator()" }

sub clone {
    my $self  = shift;
    my $class = blessed($self);
    return bless({%$self}, $class);
}

sub verify { croak blessed($_[0]) . " does not implement verify()" }

sub lines {
    my $self = shift;
    my $lines = $self->{+_LINES} or return;
    return @$lines;
}

sub cell {
    my $self = shift;

    return Term::Table::Cell->new(
        value        => 'CHECK',
        border_left  => '>',
        border_right => '<',
    ) unless $self->can('value');

    my $value = $self->value;

    return Term::Table::Cell->new(
        value        => 'NOT DEFINED',
        border_left  => '>',
        border_right => '<',
    ) unless defined $value;

    return Term::Table::Cell->new(value => "$value")
        unless ref $value;

    return ref_cell($value, $self->SHOW_ADDRESS);
}


1;
