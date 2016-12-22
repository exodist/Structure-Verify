package Structure::Verify::Check::Value::VString;
use strict;
use warnings;

use parent 'Structure::Verify::Check::Value';
use Structure::Verify::HashBase;

sub operator { 'eq' }
sub negative_operator { 'ne' }

sub init {
    my $self = shift;

    croak "'value' must be a regular expression"
        unless rtype($self->{+VALUE}) eq 'VSTRING';
}

sub verify {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $self->SUPER::verify(@_);
    return 0 unless $got->exists;
    return 0 unless $got->defined;
    return 0 unless retype($got->value) eq 'VSTRING';
    return $got->value eq $self->value ? 1 : 0;
}

1;
