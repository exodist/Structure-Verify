package Structure::Verify::Check::SubType;
use strict;
use warnings;

use Structure::Verify::CheckMaker;
use Structure::Verify::HashBase qw/-type/;

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use Structure::Verify::Util::Ref qw/render_ref/;

sub not_operator { 'ISNOTA' }
sub operator     { 'ISA' }

sub post_build {
    my $self = shift;

    $self->SUPER::post_build();

    croak "The 'type' attribute is required"
        unless $self->{+TYPE};
}

sub verify_meta {
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
    return Term::Table::Cell->new(value => render_ref($self->{+TYPE}, 1));
}

1;
