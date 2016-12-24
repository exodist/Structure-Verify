package Structure::Verify::Check;
use strict;
use warnings;

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use Structure::Verify::Util::Ref qw/rtype/;

use Structure::Verify::HashBase qw/-_lines -file -via_build/;

use Term::Table::Cell;

sub BUILD_ALIAS { }

sub init {
    my $self = shift;

    $self->{+_LINES} ||= delete $self->{lines};

    unless ($self->{+_LINES} && $self->{+FILE}) {
        my $level = 1;

        while (my @caller = caller($level++)) {
            next if $caller[0]->isa(__PACKAGE__);

            $self->{+FILE}   ||= $caller[1];
            $self->{+_LINES} ||= [$caller[2]];
        }
    }
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
