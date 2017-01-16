use Test2::Tools::Tiny;
use strict;
use warnings;

use Structure::Verify ':ALL';

ok(__PACKAGE__->can($_), "imported $_") for qw{
    build current_build

    run_checks

    check checks check_pair end etc
};

ok(!current_build, "no current build");
ok(my $meta = __PACKAGE__->STRUCTURE_VERIFY, "Got meta");

build hash => sub {
    ok(current_build->isa('Structure::Verify::Check::Hash'), "Got the current build");
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
        qr/Check 'Structure::Verify::Check::String' does not support subchecks/,
        "build must support subchecks to be built with checks"
    );
};

{

    package Structure::Verify::Check::MyCheck;
    use parent 'Structure::Verify::Check';

    our @PREV_ARGS;
    our @ARGS;

    sub init { }

    sub add_subcheck {
        my $self = shift;
        @PREV_ARGS = @ARGS;
        @ARGS      = @_;
    }
}

build my_check => sub {
    check 'aaa';
    is_deeply(\@Structure::Verify::Check::MyCheck::ARGS, [{raw => 'aaa', file => __FILE__, lines => [__LINE__ - 1]}], "1 arg, 1 arg");
    check a => 1;
    is_deeply(\@Structure::Verify::Check::MyCheck::ARGS, [a => {raw => 1, file => __FILE__, lines => [__LINE__ - 1]}], "2 args, 2 args");

    checks ['a', 'b'];
    is_deeply(\@Structure::Verify::Check::MyCheck::ARGS, [{raw => 'b', file => __FILE__, lines => [__LINE__ - 1]}], "added the check");

    checks {'a' => 'b'};
    is_deeply(\@Structure::Verify::Check::MyCheck::ARGS, ['a', {raw => 'b', file => __FILE__, lines => [__LINE__ - 1]}], "added the check with ids");

    my $line = __LINE__ + 1;
    check_pair foo => 'bar';
    is_deeply([
            @Structure::Verify::Check::MyCheck::PREV_ARGS,
            @Structure::Verify::Check::MyCheck::ARGS,
        ],
        [
            {raw => 'foo', file => __FILE__, lines => [$line]},
            {raw => 'bar', file => __FILE__, lines => [$line]},
        ],
        "added a pair of checks"
    );

    like(
        exception { end },
        qr/Current build 'Structure::Verify::Check::MyCheck' cannot be bounded/,
        "Cannot use end here"
    );

    like(
        exception { etc },
        qr/Current build 'Structure::Verify::Check::MyCheck' cannot be bounded/,
        "Cannot use etc here"
    );
};

like(
    exception { checks 'xxx' },
    qr/'checks' takes either a hashref or an arrayref/,
    "must be a ref"
);

like(
    exception {
        checks sub { 1 }
    },
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
is($h1->bounded, 1,     "bounded");
is($h2->bounded, 0,     "unbounded");

my $hx = build hash => sub {
    check 'foo' => build string => 'bar';
    check 'baz' => build string => 'bat';
    end;
};

my ($bool, $delta) = run_checks({foo => 'bar', baz => 'bat'}, $hx);
ok($bool,   "pass");
ok(!$delta, "no delta");

($bool, $delta) = run_checks({foo => 'bar1', baz => 'bat1'}, $hx);
ok(!$bool, "fail");
ok($delta, "got delta");

is(@{$delta->rows},        2,       "2 rows in delta");
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

my ($ok) = run_checks('xxx', 'xxx', convert => sub { (build(string => $_[0]), $_[1]) });
ok($ok, "Success via convert");

done_testing;
