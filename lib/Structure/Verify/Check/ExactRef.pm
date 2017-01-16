package Structure::Verify::Check::ExactRef;
use strict;
use warnings;

use Structure::Verify::CheckMaker;
use Structure::Verify::HashBase qw/-value/;

use Carp qw/croak/;
use Scalar::Util qw/refaddr/;
use Structure::Verify::Util::Ref qw/rtype/;

sub SHOW_ADDRESS { 1 }

sub noy_operator { 'IS NOT' }
sub operator     { 'IS' }

sub post_build {
    my $self = shift;

    $self->SUPER::post_build();

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

sub verify_meta {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $got->exists;
    return 0 unless $got->defined;
    return 0 unless ref($got->value);
    return 0 unless rtype($got->value) eq rtype($self->value);
    return 1;
}

sub verify_simple {
    my $self = shift;
    my ($got) = @_;

    return 0 unless refaddr($got->value) == refaddr($self->value);
    return 1;
}

1;
