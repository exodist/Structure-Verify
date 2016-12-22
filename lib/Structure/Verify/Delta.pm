package Structure::Verify::Delta;
use strict;
use warnings;

use Structure::Verify::HashBase qw/-rows/;
use Term::Table;

sub init {
    my $self = shift;

    $self->{+ROWS} ||= [];
}

sub add {
    my $self = shift;
    my ($path, $check, $got, %params) = @_;
    push @{$self->{+ROWS}} => [$path, $check, $got, %params];
}

sub term_table {
    my $self = shift;
    my %colors = @_;

    my @rows = map {
        my ($path, $check, $got, %params) = @{$_};

        [
            $path,
            join(', ' => $got->lines),
            $got->cell(\%colors),
            $check->operator,
            $check->cell(\%colors),
            $params{'*'},
            join(', ' => $check->lines),
        ]
    } @{$self->{+ROWS}};

    return Term::Table->new(
        header      => [qw/PATH GLNs GOT OP CHECK * CLNs/],
        no_collapse => [qw/GOT CHECK/],
        rows        => \@rows,
        collapse    => 1,
        sanitize    => 1,
        mark_tail   => 1,
        show_header => 1,
    );
}

1;
