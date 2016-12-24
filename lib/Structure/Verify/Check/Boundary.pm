package Structure::Verify::Check::Boundary;
use strict;
use warnings;

use Carp qw/croak/;
use parent 'Structure::Verify::Check';
use Structure::Verify::HashBase;
use Term::Table::Cell;

sub operator { '' }

sub build { croak "Cannot build a Boundary check" }

sub verify {
    my $self = shift;
    my ($got) = @_;

    return $got->exists ? 0 : 1;
}

sub cell {
    my $self = shift;

    return Term::Table::Cell->new(
        value        => 'OUT OF BOUNDS',
        border_left  => '>',
        border_right => '<',
    );
}

1;
