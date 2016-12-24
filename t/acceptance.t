use strict;
use warnings;

use Test2::Tools::Tiny;

use Structure::Verify ':ALL';

load_checks qw{
    Truthy Container Boundary Hash Object Ref Array Compound Regex VString
    Pattern Number Ref String Bag Value
};

my ($ok, $delta) = run_checks(
    { a => [ 1 ], b => 'foo', c => 'bar' },
    build hash => sub {
        check a => build array => sub {
            check build number => 1;
            end;
        };

        check b => build string => 'foo';
        check c => build string => 'bar';

        check b => build pattern => qr/foo/;
        check c => build pattern => qr/bar/;

        check b => !build pattern => qr/xxx/;
        check c => !build pattern => qr/xxx/;

        end;
    },
);

ok($ok, "Pass");

($ok, $delta) = run_checks(
    { 0 => 'xxx', a => [ 1, 2 ], b => 'foo', c => 'bar', d => 'x' },
    build hash => sub {
        check a => build array => sub {
            check build number => 2;
            end;
        };

        check b => build string => 'foox';
        check b => build pattern => qr/foox/;
        check b => !build pattern => qr/foo/;

        check c => build string => 'barx';
        check c => build pattern => qr/barx/;
        check c => !build pattern => qr/bar/;

        end;
    },
);

ok(!$ok, "Fail");

is_deeply(
    [ $delta->term_table(table_args => {max_width => 80})->render ],
    [
        '+--------------+-----+----+-----------------+---------+',
        '| PATH         | GOT | OP | CHECK           | C-LINES |',
        '+--------------+-----+----+-----------------+---------+',
        '| $_->{a}->[0] | 1   | == | 2               | 40      |',
        '| $_->{a}->[1] | 2   |    |> OUT OF BOUNDS <| 39, 42  |',
        '| $_->{b}      | foo | eq | foox            | 44      |',
        '| $_->{b}      | foo | =~ |> (?^:foox)     <| 45      |',
        '| $_->{b}      | foo | !~ |> (?^:foo)      <| 46      |',
        '| $_->{c}      | bar | eq | barx            | 48      |',
        '| $_->{c}      | bar | =~ |> (?^:barx)     <| 49      |',
        '| $_->{c}      | bar | !~ |> (?^:bar)      <| 50      |',
        '| $_->{0}      | xxx |    |> OUT OF BOUNDS <| 41, 53  |',
        '| $_->{d}      | x   |    |> OUT OF BOUNDS <| 41, 53  |',
        '+--------------+-----+----+-----------------+---------+',
    ],
    "Got useful table"
);

note map {"$_\n"} $delta->term_table(table_args => {max_width => 80})->render;

done_testing;
