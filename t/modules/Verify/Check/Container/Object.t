use Test2::Tools::Tiny;
use strict;
use warnings;

use Structure::Verify ':ALL';
use Structure::Verify::Autoload;
use Structure::Verify::Builders qw/ object /;
use Structure::Verify::Convert qw/ basic_convert /;

{
    package Bar;
    sub a { 1 };

    package Foo;
    push @Foo::ISA => 'Bar';
}

{
    package Baz;
    push @Baz::ISA => 'Foo';

    use overload (
        '""' => sub { "BAAAAZZZZ" },
    );
}

my $x = bless {}, 'Foo';

my ($ok, $delta) = run_checks(
    $x,
    object {
        check -blessed => 'Foo::X';
    },
    convert => \&basic_convert
);

ok(!$ok, "Not blessed properly");

is_deeply(
    [$delta->term_table(table_args => {max_width => 80})->render],
    [
        '+-----------------+---------+----------+-------+',
        '| GOT             | OP      | CHECK    | LINES |',
        '+-----------------+---------+----------+-------+',
        '|> Foo=HASH(...) <| BLESSED |> Foo::X <| 32    |',
        '+-----------------+---------+----------+-------+',
    ],
    "Table shows incorrect type"
);

($ok, $delta) = run_checks(
    $x,
    object {
        check -isa => 'Foo';
        check -isa => 'Bar';
        check -isa => 'Bad1';
        check -isa => 'Bad2';
        check -blessed => 'Foo';

        check a => 1;
        check a => 2;
    },
    convert => \&basic_convert
);

ok(!$ok, "Not correct");

is_deeply(
    [$delta->term_table(table_args => {max_width => 80})->render],
    [
        '+-------+-----------------+-----+-------+-------+',
        '| PATH  | GOT             | OP  | CHECK | LINES |',
        '+-------+-----------------+-----+-------+-------+',
        '|       |> Foo=HASH(...) <| ISA | Bad1  | 56    |',
        '|       |> Foo=HASH(...) <| ISA | Bad2  | 57    |',
        '| ->a() | 1               | eq  | 2     | 61    |',
        '+-------+-----------------+-----+-------+-------+',
    ],
    "Got 2 failed isa checks, and 1 failed method check"
);

my $y = bless {}, 'Baz';
($ok, $delta) = run_checks(
    $y,
    object {
        check -isa => 'Foo';
        check -isa => 'Bar';
        check -isa => 'Bad1';
        check -isa => 'Bad2';
        check -blessed => 'Baz';

        check a => 1;
    },
    convert => \&basic_convert
);

ok(!$ok, "Not correct");

is_deeply(
    [$delta->term_table(table_args => {max_width => 80})->render],
    [
        '+-----------------+-----+-------+-------+',
        '| GOT             | OP  | CHECK | LINES |',
        '+-----------------+-----+-------+-------+',
        '|> Baz=HASH(...) <| ISA | Bad1  | 88    |',
        '|  BAAAAZZZZ      |     |       |       |',
        '|                 |     |       |       |',
        '|> Baz=HASH(...) <| ISA | Bad2  | 89    |',
        '|  BAAAAZZZZ      |     |       |       |',
        '+-----------------+-----+-------+-------+',
    ],
    "Showed the stringified form as well"
);

#note map {"$_\n"} $delta->term_table(table_args => {max_width => 80})->render;

done_testing;
