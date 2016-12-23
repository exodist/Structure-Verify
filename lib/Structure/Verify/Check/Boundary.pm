package Structure::Verify::Check::Boundary;
use strict;
use warnings;

use Carp qw/croak/;
use parent 'Structure::Verify::Check';
use Structure::Verify::HashBase;

sub operator { '' }

sub cell {
    my $self = shift;

    return Term::Table::Cell->new(
        value        => 'OUT OF BOUNDS',
        border_left  => '>',
        border_right => '<',
    );
}

1;
