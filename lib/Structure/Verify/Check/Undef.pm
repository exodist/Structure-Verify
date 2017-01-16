package Structure::Verify::Check::Undef;
use strict;
use warnings;

use Structure::Verify::CheckMaker;
use Structure::Verify::HashBase;

sub not_operator { 'IS NOT' }
sub operator     { 'IS' }

sub verify_meta {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $got->exists;
    return 1;
}

sub verify_simple {
    my $self = shift;
    my ($got) = @_;

    return 1 unless $got->defined;
    return 0;
}

1;
