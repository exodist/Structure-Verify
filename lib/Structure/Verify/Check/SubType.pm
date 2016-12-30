package Structure::Verify::Check::SubType;
use strict;
use warnings;

use parent 'Structure::Verify::Check';

use Structure::Verify::HashBase qw/-type/;

use Carp qw/croak/;
use Scalar::Util qw/blessed/;

sub BUILD_ALIAS { 'subtype' }

sub operator { 'ISA' }

sub init {
    my $self = shift;

    $self->SUPER::init();

    return if $self->via_build;

    croak "The 'type' attribute is required"
        unless $self->{+TYPE};
}

sub verify {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $got->exists;
    return 0 unless $got->defined;

    my $value = $got->value;

    return 0 unless blessed($value);

    return $value->isa($self->{+TYPE}) ? 1 : 0;
}

sub build {
    my $self = shift;
    my ($with, $alias) = @_;

    if (ref($with)) {
        my $class = blessed($self);
        croak "'$class' does not know how to build with '$with'"
    }

    $self->{+TYPE} = $with;
}

sub cell {
    my $self = shift;
    return Term::Table::Cell->new(value => $self->{+TYPE});
}

1;
