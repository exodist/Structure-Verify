package Structure::Verify::Check::VString;
use strict;
use warnings;

use Structure::Verify::CheckMaker;
use Structure::Verify::HashBase qw/-value/;

use Carp qw/croak/;
use Scalar::Util qw/isvstring/;
use Structure::Verify::Util::Ref qw/rtype/;

sub not_operator { 'ne' }
sub operator     { 'eq' }

sub post_build {
    my $self = shift;

    $self->SUPER::post_build();

    croak "'value' must be a vstring"
        unless isvstring($self->{+VALUE});
}

sub verify_meta {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $got->exists;
    return 0 unless $got->defined;
    return 0 unless isvstring($got->value);
    return 1;
}

sub verify_Simple {
    my $self = shift;
    my ($got) = @_;

    return $got->value eq $self->value ? 1 : 0;
}

sub build {
    my $self = shift;
    my ($with, $alias) = @_;

    my $type = rtype($with);

    return $self->{$self->VALUE} = $with
        if $type eq 'VSTRING';

    $self->SUPER::build(@_);
}

1;
