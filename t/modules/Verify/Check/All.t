use strict;
use warnings;
BEGIN { require 't/is.pm'; is->import }

use Structure::Verify::Builders qw/all(&)/;

my $CLASS = 'Structure::Verify::Check::All';

is(
    ['abc'],
    [
        all {
            check qr/a/;
            check qr/b/;
            check qr/c/;
        }
    ],
    "This passes",
);

my $events = intercept {
    local $ENV{TABLE_TERM_SIZE} = 150;
    is(
        ['a', 'x'],
        [
            all {
                check 'a';
                check 'b';
                check 'c';
            },
            all {
                check 'a';
                check 'b';
                check 'c';
            },
        ],
        "This passes",
    );
};

my $delta = last_delta;

ok(!$events->[0]->pass, "Did not pass");
is($events->[-1]->message . "\n", <<EOT, "Got the table we wanted");
+------+-----+-----+-------+---+--------+
| PATH | GOT | OP  | CHECK | * | LINES  |
+------+-----+-----+-------+---+--------+
| [0]  | a   | ALL |> ... <|   | 26, 30 |
|      |     | eq  | a     | * | 27     |
|      |     | eq  | b     |   | 28     |
|      |     | eq  | c     |   | 29     |
|      |     |     |       |   |        |
| [1]  | x   | ALL |> ... <|   | 31, 35 |
|      |     | eq  | a     |   | 32     |
|      |     | eq  | b     |   | 33     |
|      |     | eq  | c     |   | 34     |
+------+-----+-----+-------+---+--------+
EOT

is(
    $delta,
    object {
        check -isa => 'Structure::Verify::Delta';
        check rows => array {
            check array {
                check '[0]';
                check array {
                    check object { check -isa => 'Structure::Verify::Check::All' };
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
                    check object { check -isa => 'Structure::Verify::Check::All' };
                    check ' ';
                    check object { check -isa => 'Structure::Verify::Check::String' };
                    check ' ';
                    check object { check -isa => 'Structure::Verify::Check::String' };
                    check ' ';
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
