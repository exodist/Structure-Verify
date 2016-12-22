package Structure::Verify::Check::Value::String;
use strict;
use warnings;

use parent 'Structure::Verify::Check::Value';
use Structure::Verify::HashBase;

sub operator { 'eq' }
sub negative_operator { 'ne' }

sub verify {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $self->SUPER::verify(@_);
    return 0 unless $got->exists;
    return 0 unless $got->defined;
    return $got->value eq $self->value ? 1 : 0;
}

1;
