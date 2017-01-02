package Structure::Verify::Check::Value::Ref;
use strict;
use warnings;

use parent 'Structure::Verify::Check::Value';
use Structure::Verify::HashBase;
use Structure::Verify::Behaviors::Negatable;

use Carp qw/croak/;
use Scalar::Util qw/refaddr/;
use Structure::Verify::Util::Ref qw/rtype/;

sub BUILD_ALIAS { 'exact_ref' }
sub SHOW_ADDRESS { 1 }

sub operator { $_[0]->negate ? 'IS NOT' : 'IS' }

sub init {
    my $self = shift;

    $self->SUPER::init();
    return if $self->{+VIA_BUILD};

    croak "'value' must be a reference"
        unless ref($self->{+VALUE});
}

sub build {
    my $self = shift;
    my ($with, $alias) = @_;

    return $self->{+VALUE} = $with
        if rtype($with);

    return $self->SUPER::build(@_);
}

sub verify {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $self->SUPER::verify(@_);
    return 0 unless $got->exists;
    return 0 unless $got->defined;
    return 0 unless ref($got->value);
    return 0 unless rtype($got->value) eq rtype($self->value);
    return 0 unless refaddr($got->value) == refaddr($self->value);
    return 1;
}

1;
