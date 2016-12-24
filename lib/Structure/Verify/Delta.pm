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
    my $self   = shift;
    my %params = @_;

    my $colors     = $params{colors};
    my $table_args = $params{table_args} || {};

    my @rows = map {
        my ($path, $check, $got, %params) = @{$_};

        [
            $path,
            join(', ' => $got->lines),
            $got->cell($colors),
            $check->operator,
            $check->cell($colors),
            $params{'*'} || '',
            join(', ' => $check->lines),
        ]
    } @{$self->{+ROWS}};

    # Sort by path Not sure if I want this. Keeping it in defined order might
    # be best. This also causes 'OUT OF BOUNDS' keys to be scattered
    # alphabetically instead of all grouped at the end.
#    @rows = sort {
#        my $av = $a->[0];
#        my $bv = $b->[0];
#        $av =~ s/^\$_//;
#        $bv =~ s/^\$_//;
#        $av =~ s/->//g;
#        $bv =~ s/->//g;
#
#        my @a = grep {defined $_} $av =~ m/(?:\{([^\}]+)\}|\[([^\]]+)\]|([\w\d_\-\.]+))/g;
#        my @b = grep {defined $_} $bv =~ m/(?:\{([^\}]+)\}|\[([^\]]+)\]|([\w\d_\-\.]+))/g;
#
#        while (@a && @b) {
#            my $av = shift @a;
#            my $bv = shift @b;
#
#            my $d;
#            if ("$av$bv" =~ m/^[\d\.]+$/) {
#                $d = $av <=> $bv;
#            }
#            else {
#                $d = $av cmp $bv;
#            }
#
#            return $d if $d;
#        }
#
#        return scalar(@a) <=> scalar(@b);
#    } @rows;

    return Term::Table->new(
        collapse    => 1,
        sanitize    => 1,
        mark_tail   => 1,
        show_header => 1,

        %$table_args,

        header      => [qw/PATH G-LINES GOT OP CHECK * C-LINES/],
        no_collapse => [qw/GOT CHECK/],
        rows        => \@rows,
    );
}

1;
