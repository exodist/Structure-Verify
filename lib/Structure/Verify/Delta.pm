package Structure::Verify::Delta;
use strict;
use warnings;

use Structure::Verify::HashBase qw/-rows/;
use Term::Table;
use Term::Table::Cell;
use Term::Table::Spacer;

sub init {
    my $self = shift;

    $self->{+ROWS} ||= [];
}

sub add {
    my $self = shift;
    my ($path, $check, $got, %params) = @_;
    push @{$self->{+ROWS}} => [$path, $check, $got, %params];
}

my $SPACE = [];

sub add_space {
    my $self = shift;
    push @{$self->{+ROWS}} => $SPACE;
}

sub term_table {
    my $self   = shift;
    my %params = @_;

    my $colors     = $params{colors};
    my $table_args = $params{table_args} || {};

    my @rows = map {
        my ($path, $check, $got, %params) = @{$_};

        $_ == $SPACE ? [Term::Table::Spacer->new] : [
            $path,
            $got->isa('Term::Table::Cell') ? (
                undef,
                $got
            ) : (
                join(', ' => $got->lines),
                $got->cell($colors),
            ),
            $check->operator,
            $check->cell($colors),
            $params{'*'} || '',
            join(', ' => $check->lines),
            $params{'notes'},
        ]
    } @{$self->{+ROWS}};

    pop @rows if $self->{+ROWS}->[-1] == $SPACE;

    return Term::Table->new(
        collapse    => 1,
        sanitize    => 1,
        mark_tail   => 1,
        show_header => 1,

        %$table_args,

        header      => [qw/PATH LINES GOT OP CHECK * LINES NOTES/],
        no_collapse => [qw/GOT CHECK/],
        rows        => \@rows,
    );
}

1;
