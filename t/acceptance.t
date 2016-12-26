use Test2::Tools::Tiny;
use strict;
use warnings;

use Test2::API qw/context/;

use Structure::Verify ':ALL';
use Structure::Verify::Builders(
    qw{ Hash Array },
    Hash => {-as => 'hoot'},
    Hash => {-as => 'hoop'},
);

load_checks qw{
    Truthy Container Boundary Hash Object Ref Array Compound Regex VString
    Pattern Number Ref String Bag Value
};

ok(__PACKAGE__->can($_), "imported $_()") for qw/hash array hoop hoot/;

my $convert = sub {
    my $in = shift;

    return $in
        if $in->isa('Structure::Verify::Check')
        && !$in->isa('Structure::Verify::Check::Stem');

    return Structure::Verify::Check::Value::String->new(value => $in->stem);
};

sub isx($$;$) {
    my ($ok, $delta) = run_checks($_[0], $_[1], convert => $convert);
    my $ctx = context;
    ok($ok, $_[2]) || diag map {"$_\n"} $delta->term_table(table_args => {max_width => 80})->render;
    $ctx->release;
    return $ok;
}

isx(
    { a => [ 1 ], b => 'foo', c => 'bar' },
    hoot {
        check a => build array => sub {
            check build number => 1;
            end;
        };

        check b => 'foo';
        check b => build string => 'foo';
        check b => !build pattern => qr/xxx/;
        check b => build pattern => qr/foo/;

        check c => 'bar';
        check c => build string => 'bar';
        check c => build pattern => qr/bar/;
        check c => !build pattern => qr/xxx/;

        end;
    },
    "Passing test",
);

my ($ok, $delta) = run_checks(
    { 0 => 'xxx', a => [ 1, 2 ], b => "foo\nfoo  \t", c => 'bar', d => 'x' },
    build(hash => sub {
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
    }),
    convert => $convert,
);

ok(!$ok, "Fail");

is_deeply(
    [$delta->term_table(table_args => {max_width => 80})->render],
    [
        '+--------+---------+----+-----------------+--------+',
        '| PATH   | GOT     | OP | CHECK           | LINES  |',
        '+--------+---------+----+-----------------+--------+',
        '| {a}[0] | 1       | == | 2               | 66     |',
        '| {a}[1] | 2       |    |> OUT OF BOUNDS <| 65, 68 |',
        '|        |         |    |                 |        |',
        '| {b}    | foo\n   | eq | foox            | 70     |',
        '|        | foo  \t |    |                 |        |',
        '|        |         |    |                 |        |',
        '| {b}    | foo\n   | =~ |> (?^:foox)     <| 71     |',
        '|        | foo  \t |    |                 |        |',
        '|        |         |    |                 |        |',
        '| {b}    | foo\n   | !~ |> (?^:foo)      <| 72     |',
        '|        | foo  \t |    |                 |        |',
        '|        |         |    |                 |        |',
        '| {c}    | bar     | eq | barx            | 74     |',
        '| {c}    | bar     | =~ |> (?^:barx)     <| 75     |',
        '| {c}    | bar     | !~ |> (?^:bar)      <| 76     |',
        '| {0}    | xxx     |    |> OUT OF BOUNDS <| 67, 79 |',
        '| {d}    | x       |    |> OUT OF BOUNDS <| 67, 79 |',
        '+--------+---------+----+-----------------+--------+',
    ],
    "Got useful table"
);

#note map {"$_\n"} $delta->term_table(table_args => {max_width => 80})->render;

done_testing;
