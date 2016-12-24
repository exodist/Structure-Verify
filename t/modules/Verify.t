use Test2::Tools::Tiny;
use strict;
use warnings;

use Structure::Verify ':ALL';

ok(__PACKAGE__->can($_), "imported $_") for qw{
    build current_build

    run_checks

    check checks end etc

    load_check    load_checks
    load_check_as load_checks_as
};

load_check 'Hash';
load_checks qw/Array String/;
load_check_as 'Hash' => 'foo';
load_checks_as Array => 'bar', String => 'baz';

ok($INC{'Structure/Verify/Check/Container/Hash.pm'}, "Loaded hash");
ok($INC{'Structure/Verify/Check/Container/Array.pm'}, "Loaded array");
ok($INC{'Structure/Verify/Check/Value/String.pm'}, "Loaded string");

ok(my $meta = __PACKAGE__->STRUCTURE_VERIFY, "Got meta");

is_deeply(
    $meta->build_map,
    {
        hash => 'Structure::Verify::Check::Container::Hash',
        foo  => 'Structure::Verify::Check::Container::Hash',

        array => 'Structure::Verify::Check::Container::Array',
        bar   => 'Structure::Verify::Check::Container::Array',

        string => 'Structure::Verify::Check::Value::String',
        baz    => 'Structure::Verify::Check::Value::String',
    },
    "Set up our build map"
);

ok(!current_build, "no current build");

build hash => sub {
    ok(current_build->isa('Structure::Verify::Check::Container::Hash'), "Got the current build");
};

my $h = build hash => sub {
    check 'foo' => build string => 'bar';
    check 'baz' => build string => 'bat';
};
is_deeply([$h->lines], [__LINE__ - 4, __LINE__ - 1], "Got line numbers");
is_deeply($h->file, __FILE__, "got filename");

like(exception { check 'aaa' }, qr/No current build/, "Cannot use check() without a build");
like(exception { checks ['aaa'] }, qr/No current build/, "Cannot use checks() without a build");

build 'string' => sub {
    like(
        exception { check 'aaa' },
        qr/Check 'Structure::Verify::Check::Value::String' does not support subchecks/,
        "build must support subchecks to be built with checks"
    );
};

{
    package MyCheck;
    use parent 'Structure::Verify::Check';

    our @ARGS;

    sub init { }

    sub add_subcheck {
        my $self = shift;
        @ARGS = @_;
    }
}

$meta->build_map->{'cc'} = 'MyCheck';

build cc => sub {
    check 'aaa';
    is_deeply(\@MyCheck::ARGS, ['aaa'], "1 arg, 1 arg");
    check a => 1;
    is_deeply(\@MyCheck::ARGS, [a => 1], "2 args, 2 args");

    checks [ 'a', 'b' ];
    is_deeply(\@MyCheck::ARGS, ['b'], "added the check");

    checks { 'a' => 'b' };
    is_deeply(\@MyCheck::ARGS, ['a', 'b'], "added the check with ids");

    like(
        exception { end },
        qr/Current build 'MyCheck' cannot be bounded/,
        "Cannot use end here"
    );

    like(
        exception { etc },
        qr/Current build 'MyCheck' cannot be bounded/,
        "Cannot use etc here"
    );
};

like(
    exception { checks 'xxx' },
    qr/'checks' takes either a hashref or an arrayref/,
    "must be a ref"
);

like(
    exception { checks sub { 1 } },
    qr/'checks' takes either a hashref or an arrayref/,
    "must be a has or array ref"
);

like(
    exception { checks [1] },
    qr/No current build/,
    "checks() needs a build"
);

like(
    exception { end },
    qr/No current build/,
    "Cannot use end here"
);

like(
    exception { etc },
    qr/No current build/,
    "Cannot use etc here"
);

my $h0 = build hash => sub { };
my $h1 = build hash => sub { end };
my $h2 = build hash => sub { etc };

is($h0->bounded, undef, "not set");
is($h1->bounded, 1, "bounded");
is($h2->bounded, 0, "unbounded");

my $hx = build hash => sub {
    check 'foo' => build string => 'bar';
    check 'baz' => build string => 'bat';
    end;
};

my ($bool, $delta) = run_checks({foo => 'bar', baz => 'bat'}, $hx);
ok($bool, "pass");
ok(!$delta, "no delta");

($bool, $delta) = run_checks({foo => 'bar1', baz => 'bat1'}, $hx);
ok(!$bool, "fail");
ok($delta, "got delta");

is(@{$delta->rows}, 2, "2 rows in delta");
is($delta->rows->[0]->[0], '{foo}', "first row is foo");
is($delta->rows->[1]->[0], '{baz}', "second row is baz");

like(
    exception { run_checks({}, 'xxx') },
    qr/'xxx' is not a valid check/,
    "Must have a valid check"
);

like(
    exception { run_checks({a => {}}, build hash => {a => 'xxx'}) },
    qr/{a}: 'xxx' is not a valid check/,
    "Must have a valid check (nested)"
);

my ($ok) = run_checks('xxx', 'xxx', convert => sub { build string => $_[0] } );
ok($ok, "Success via convert");

done_testing;
