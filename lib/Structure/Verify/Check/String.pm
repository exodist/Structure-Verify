package Structure::Verify::Check::String;
use strict;
use warnings;

use Structure::Verify::CheckMaker;
use Structure::Verify::HashBase qw/-value/;

sub not_operator { 'ne' }
sub operator     { 'eq' }

sub verify_meta {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $got->exists;
    return 0 unless $got->defined;
    return 1;
}

sub verify_simple {
    my $self = shift;
    my ($got) = @_;

    return $got->value eq $self->value ? 1 : 0;
}

1;
