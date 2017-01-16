package Structure::Verify::Check::Number;
use strict;
use warnings;

use Structure::Verify::CheckMaker;
use Structure::Verify::HashBase qw/-value/;

use Scalar::Util qw/looks_like_number/;

sub not_operator { '!=' }
sub operator     { '==' }

sub verify_type {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $got->exists;
    return 0 unless $got->defined;
    return 0 unless looks_like_number($got->value);
    return 1;
}

sub verify {
    my $self = shift;
    my ($got) = @_;

    return $got->value == $self->value ? 1 : 0;
}

1;
