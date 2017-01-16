package Structure::Verify::Check;
use strict;
use warnings;

use Carp qw/croak carp/;
use Scalar::Util qw/blessed/;
use Structure::Verify::Util::Ref qw/rtype ref_cell/;

use Structure::Verify::HashBase qw/-_lines -file -building/;

use Term::Table::Cell;
use Structure::Verify::Meta;

sub SHOW_ADDRESS { 0 }

sub not_operator { '!' . $_[0]->operator }
sub operator     { croak((blessed($_[0]) || $_[0]) . " does not implement operator()") }
sub verify_type  { croak((blessed($_[0]) || $_[0]) . " does not implement verify_type()") }
sub verify       { croak((blessed($_[0]) || $_[0]) . " does not implement verify()") }

sub clone {
    my $self  = shift;
    my $class = blessed($self);
    return bless({%$self}, $class);
}

sub lines {
    my $self = shift;
    my $lines = $self->{+_LINES} or return;
    return @$lines;
}

sub init {
    my $self = shift;
    $self->pre_build();
    $self->post_build();
}

sub new_build {
    my $class = shift;
    my $self = bless {@_}, $class;
    $self->pre_build;
    return $self;
}

sub pre_build {
    my $self = shift;
    $self->{+BUILDING} = 1;
    $self->{+_LINES} ||= delete $self->{lines};
}

sub post_build {
    my $self = shift;
    $self->{+BUILDING} = 0;
}

sub negate {
    my $self = shift;
    require Structure::Verify::Check::Not;
    return Structure::Verify::Check::Not->new(check => $self);
}

sub build {
    my $self = shift;
    my ($with, $alias) = @_;

    return unless defined $with;

    my $type = rtype($with);

    return $with->($self, $alias)
        if $type eq 'CODE';

    return $self->{$self->VALUE} = $with
        if $self->can('value') && (!$type || $type eq 'REGEXP');

    my $class = blessed($self);
    croak "'$class' does not know how to build with '$with'"
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
