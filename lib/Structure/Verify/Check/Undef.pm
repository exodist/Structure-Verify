package Structure::Verify::Check::Undef;
use strict;
use warnings;

use parent 'Structure::Verify::Check';
use Structure::Verify::HashBase;
use Structure::Verify::Behaviors::Negatable;

sub operator { $_[0]->negate ? 'IS' : 'IS NOT' }

sub verify {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $got->exists;
    return 1 unless $got->defined;
    return 0;
}

1;
