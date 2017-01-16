package Structure::Verify::Check::Boundary;
use strict;
use warnings;

use Carp qw/croak/;
use Structure::Verify::CheckMaker;
use Term::Table::Cell;

sub operator     { '' }
sub not_operator { '' }

sub build { croak "Cannot build a Boundary check" }

sub verify_type { undef }

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
