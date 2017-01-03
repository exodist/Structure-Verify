use Test2::Tools::Tiny;
use strict;
use warnings;

use Structure::Verify ':ALL';
use Structure::Verify::Convert qw/convert/;
use Structure::Verify::Builders qw/bag/;
use List::Util qw/shuffle/;

my $c = sub { convert($_[0], $_[1], {use_regex => 1}) };

my ($bool, $delta) = run_checks(
    [shuffle qw/ foo bar baz /],
    bag {
        check $_ for shuffle qw/ foo bar baz /;
        check 2 => qr/a/;
        end;
    },
    convert => $c,
);

ok($bool, "Pass") || diag map {"$_\n"} $delta->term_table(table_args => {max_width => 80})->render;

($bool, $delta) = run_checks(
    [qw/ x y z a foo bar baz /],
    bag {
        check 'foo';
        check 'bar';
        check 'baz';
        check 2 => qr/a/;
        end;
    },
    convert => $c,
);

ok(!$bool, "Check for extra stuff");

is_deeply(
    [$delta->term_table(table_args => {max_width => 80})->render],
    [
        '+------+-----+----+-----------------+--------+--------------+',
        '| PATH | GOT | OP | CHECK           | LINES  | NOTES        |',
        '+------+-----+----+-----------------+--------+--------------+',
        '| <3>  | a   | =~ |> (?^:a)        <| 30     | Match 1 of 2 |',
        '| <3>  | bar | =~ |> (?^:a)        <| 30     | Match 2 of 2 |',
        '| <3>  | baz | =~ |> (?^:a)        <| 30     | Match 3 of 2 |',
        '|      |     |    |                 |        |              |',
        '| [0]  | x   |    |> OUT OF BOUNDS <| 26, 32 |              |',
        '| [1]  | y   |    |> OUT OF BOUNDS <| 26, 32 |              |',
        '| [2]  | z   |    |> OUT OF BOUNDS <| 26, 32 |              |',
        '+------+-----+----+-----------------+--------+--------------+',
    ],
    "Got table of extras"
);

($bool, $delta) = run_checks(
    [qw/ x y z a foo bar baz /],
    bag {
        check 'foo';
        check 'bar';
        check 'baz';
        check 2 => qr/a/;
        etc;
    },
    convert => $c,
);

ok(!$bool, "Check for extra matches, but not extra items");

is_deeply(
    [$delta->term_table(table_args => {max_width => 80})->render],
    [
        '+------+-----+----+----------+-------+--------------+',
        '| PATH | GOT | OP | CHECK    | LINES | NOTES        |',
        '+------+-----+----+----------+-------+--------------+',
        '| <3>  | a   | =~ |> (?^:a) <| 62    | Match 1 of 2 |',
        '| <3>  | bar | =~ |> (?^:a) <| 62    | Match 2 of 2 |',
        '| <3>  | baz | =~ |> (?^:a) <| 62    | Match 3 of 2 |',
        '+------+-----+----+----------+-------+--------------+',
    ],
    "Got table of extras matches"
);

($bool, $delta) = run_checks(
    [shuffle qw/ foo bar baz /],
    bag {
        check $_ for shuffle qw/ foo bar baz /;
        check qr/a/;
        etc;
    },
    convert => $c,
);

ok($bool, "No count specified, any number works") || diag map {"$_\n"} $delta->term_table(table_args => {max_width => 80})->render;

($bool, $delta) = run_checks(
    [qw/ foo bar baz /],
    bag {
        check 'foo';
        check 'bar';
        check 'baz';
        check qr/a/;
        end;
    },
    convert => $c,
);

ok(!$bool, "check count defaults to 1 in bounded mode");

is_deeply(
    [$delta->term_table(table_args => {max_width => 80})->render],
    [
        '+------+-----+----+----------+-------+--------------+',
        '| PATH | GOT | OP | CHECK    | LINES | NOTES        |',
        '+------+-----+----+----------+-------+--------------+',
        '| <3>  | bar | =~ |> (?^:a) <| 102   | Match 1 of 1 |',
        '| <3>  | baz | =~ |> (?^:a) <| 102   | Match 2 of 1 |',
        '+------+-----+----+----------+-------+--------------+',
    ],
    "Got table of extras matches"
);


done_testing;
