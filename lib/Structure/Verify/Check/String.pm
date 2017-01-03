package Structure::Verify::Check::String;
use strict;
use warnings;

use parent 'Structure::Verify::Check';
use Structure::Verify::HashBase qw/-value/;
use Structure::Verify::Behaviors::Negatable;

sub operator { $_[0]->negate ? 'ne' : 'eq' }

sub verify {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $got->exists;
    return 0 unless $got->defined;

    my ($pass, $fail) = $self->negate ? (0, 1) : (1, 0);
    return $got->value eq $self->value ? $pass : $fail;
}

1;
