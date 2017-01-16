use strict;
use warnings;
BEGIN { require 't/is.pm'; is->import }

use Structure::Verify::Builders qw/none(&)/;

my $CLASS = 'Structure::Verify::Check::None';

is(
    ['x'],
    [
        none {
            check 'a';
            check 'b';
            check 'c';
        }
    ],
    "This passes",
);

my $events = intercept {
    local $ENV{TABLE_TERM_SIZE} = 150;
    is(
        ['a', 'a'],
        [
            none {
                check 'a';
                check 'b';
                check 'c';
            },
            none {
                check 'a';
                check 'a';
                check 'b';
            },
        ],
        "This fails",
    );
};

my $delta = last_delta;

ok(!$events->[0]->pass, "Did not pass");
is($events->[-1]->message . "\n", <<EOT, "Got the table we wanted");
+------+-----+------+-------+---+--------+
| PATH | GOT | OP   | CHECK | * | LINES  |
+------+-----+------+-------+---+--------+
| [0]  | a   | NONE |> ... <|   | 26, 30 |
|      |     | eq   | a     | * | 27     |
|      |     | eq   | b     |   | 28     |
|      |     | eq   | c     |   | 29     |
|      |     |      |       |   |        |
| [1]  | a   | NONE |> ... <|   | 31, 35 |
|      |     | eq   | a     | * | 32     |
|      |     | eq   | a     | * | 33     |
|      |     | eq   | b     |   | 34     |
+------+-----+------+-------+---+--------+
EOT

is(
    $delta,
    object {
        check -isa => 'Structure::Verify::Delta';
        check rows => array {
            check array {
                check '[0]';
                check array {
                    check object { check -isa => 'Structure::Verify::Check::None' };
                    check ' ';
                    check object { check -isa => 'Structure::Verify::Check::String' };
                    check '*';
                    check object { check -isa => 'Structure::Verify::Check::String' };
                    check ' ';
                    check object { check -isa => 'Structure::Verify::Check::String' };
                    check ' ';
                    end;
                };
                check object { check -isa => 'Structure::Verify::Got' };
                end;
            };
            check array {
                check '[1]';
                check array {
                    check object { check -isa => 'Structure::Verify::Check::None' };
                    check ' ';
                    check object { check -isa => 'Structure::Verify::Check::String' };
                    check '*';
                    check object { check -isa => 'Structure::Verify::Check::String' };
                    check '*';
                    check object { check -isa => 'Structure::Verify::Check::String' };
                    check ' ';
                    end;
                };
                check object { check -isa => 'Structure::Verify::Got' };
                end;
            };
            end;
        };
    },
    "Got delta, it is a 2-entry delta"
);

done_testing;
