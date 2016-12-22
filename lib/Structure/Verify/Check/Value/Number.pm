package Structure::Verify::Check::Value::Number;
use strict;
use warnings;

use parent 'Structure::Verify::Check::Value';
use Structure::Verify::HashBase;

sub operator { '==' }
sub negative_operator { '!=' }

sub verify {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $self->SUPER::verify(@_);
    return 0 unless $got->exists;
    return 0 unless $got->defined;
    return $got->value == $self->value ? 1 : 0;
}

1;
