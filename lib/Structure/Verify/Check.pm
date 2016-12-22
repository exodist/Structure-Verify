package Structure::Verify::Check;
use strict;
use warnings;

use Carp qw/croak/;
use Scalar::Util qw/blessed/;

use Structure::Verify::HashBase qw/-_lines -file/;

sub init {
    my $self = shift;
    $self->{+_LINES} ||= delete $self->{lines};
}

sub operator { croak blessed($_[0]) . " does not implement operator()" }
sub negative_operator { '!' . shift->operator }

sub verify { croak blessed($_[0]) . " does not implement verify()" }

sub lines {
    my $self = shift;
    my $lines = $self->{+_LINES} or return;
    return @$lines;
}

sub cell {
    my $self = shift;

    return Term::Table::Cell->new(
        value        => 'CHECK',
        border_left  => '>',
        border_right => '<',
    );
}

1;
