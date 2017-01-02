package Structure::Verify::Check;
use strict;
use warnings;

use Carp qw/croak carp/;
use Scalar::Util qw/blessed/;
use Structure::Verify::Util::Ref qw/rtype/;

use Structure::Verify::HashBase qw/-_lines -file -via_build/;

use Term::Table::Cell;
use Structure::Verify::Meta;

sub BUILD_ALIAS { }

sub SHOW_ADDRESS { 0 }

sub import {
    my $class = shift;
    my @aliases = @_;

    @aliases = $class->BUILD_ALIAS unless @aliases;
    return unless @aliases;

    my $meta = Structure::Verify::Meta->new(scalar caller);
    $meta->add_alias($_, $class) for @aliases;
}

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

    return $with->($self, $alias)
        if rtype($with) eq 'CODE';

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
    );
}

1;
