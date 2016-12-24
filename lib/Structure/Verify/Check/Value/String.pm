package Structure::Verify::Check::Value::String;
use strict;
use warnings;

use parent 'Structure::Verify::Check::Value';
use Structure::Verify::HashBase;
use Structure::Verify::Behaviors::Negatable;

sub BUILD_ALIAS { 'string' }

sub operator { $_[0]->negate ? 'ne' : 'eq' }

sub verify {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $self->SUPER::verify(@_);
    return 0 unless $got->exists;
    return 0 unless $got->defined;

    my ($pass, $fail) = $self->negate ? (0, 1) : (1, 0);
    return $got->value eq $self->value ? $pass : $fail;
}

1;
