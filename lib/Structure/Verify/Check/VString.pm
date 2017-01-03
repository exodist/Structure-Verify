package Structure::Verify::Check::VString;
use strict;
use warnings;

use parent 'Structure::Verify::Check';
use Structure::Verify::HashBase qw/-value/;
use Structure::Verify::Behaviors::Negatable;

use Carp qw/croak/;
use Scalar::Util qw/isvstring/;

sub operator { $_[0]->negate ? 'ne' : 'eq' }

sub init {
    my $self = shift;

    $self->SUPER::init();
    return if $self->{+VIA_BUILD};

    croak "'value' must be a vstring"
        unless isvstring($self->{+VALUE});
}

sub verify {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $got->exists;
    return 0 unless $got->defined;
    return 0 unless isvstring($got->value);

    my ($pass, $fail) = $self->negate ? (0, 1) : (1, 0);
    return $got->value eq $self->value ? $pass : $fail;
}

1;
