use Test2::Tools::Tiny;
use strict;
use warnings;

use Structure::Verify::Got;

my $CLASS = 'Structure::Verify::Got';

my $one = $CLASS->new();
ok($one->isa($CLASS), "Created an instance");
is($one->exists, 0, "Does not exist, we get an explicit 0");
is($one->defined, 0, "Not defined, we get an explicit 0");
is_deeply([$one->value], [], "value returns nothing in list context");
is(scalar $one->value, undef, "undefined in scalar context");

$one = $CLASS->new(undef);
ok($one->isa($CLASS), "Created an instance");
is($one->exists, 1, "Does exist, we get an explicit 1");
is($one->defined, 0, "Not defined, we get an explicit 0");
is_deeply([$one->value], [undef], "value returns undef in list context");
is(scalar $one->value, undef, "undefined in scalar context");

$one = $CLASS->new(0);
ok($one->isa($CLASS), "Created an instance");
is($one->exists, 1, "Does exist, we get an explicit 1");
is($one->defined, 1, "Defined, we get an explicit 1");
is_deeply([$one->value], [0], "value returned in list context");
is(scalar $one->value, 0, "value returned in scalar context");

$one = $CLASS->new(2);
ok($one->isa($CLASS), "Created an instance");
is($one->exists, 1, "Does exist, we get an explicit 1");
is($one->defined, 1, "Defined, we get an explicit 1");
is_deeply([$one->value], [2], "value returned in list context");
is(scalar $one->value, 2, "value returned in scalar context");

my $arr = [2,3,4];
$one = $CLASS->new($arr, 0);
ok($one->isa($CLASS), "Created an instance");
is($one->exists, 1, "Does exist, we get an explicit 1");
is($one->defined, 1, "Defined, we get an explicit 1");
is_deeply([$one->value], [2], "value returned in list context");
is(scalar $one->value, 2, "value returned in scalar context");

$one = $CLASS->new($arr, 5);
ok($one->isa($CLASS), "Created an instance");
is($one->exists, 0, "Does not exist, we get an explicit 0");
is($one->defined, 0, "Not defined, we get an explicit 0");
is_deeply([$one->value], [], "value returns nothing in list context");
is(scalar $one->value, undef, "undefined in scalar context");
is(@$arr, 3, "Did not vivify");

my $hash = { a => 'a', b => 'b', c => 'c' };
$one = $CLASS->new($hash, 'b');
ok($one->isa($CLASS), "Created an instance");
is($one->exists, 1, "Does exist, we get an explicit 1");
is($one->defined, 1, "Defined, we get an explicit 1");
is_deeply([$one->value], ['b'], "value returned in list context");
is(scalar $one->value, 'b', "value returned in scalar context");

$one = $CLASS->new($hash, 'd');
ok($one->isa($CLASS), "Created an instance");
is($one->exists, 0, "Does not exist, we get an explicit 0");
is($one->defined, 0, "Not defined, we get an explicit 0");
is_deeply([$one->value], [], "value returns nothing in list context");
is(scalar $one->value, undef, "undefined in scalar context");
ok(!exists $hash->{d}, "Did not vivify");

like(
    exception { $CLASS->new(1,2,3) },
    qr/Too many arguments provided to the constructor/,
    "Too many arguments"
);

like(
    exception { $CLASS->new(1,2) },
    qr/The first argument in the 2-arg constructor must be a reference/,
    "First arg must be a ref"
);

like(
    exception { $CLASS->new([], 'x') },
    qr/The second argument in the 2-arg constructor must be an integer when the first argument is an arrayref/,
    "Second arg in array constructor must be an integer"
);

like(
    exception { $CLASS->new({}, undef) },
    qr/The second argument in the 2-arg constructor must be defined when the first argument is a hashref/,
    "Second arg in hash constructor must be defined"
);

like(
    exception { $CLASS->new(qr/xxx/, undef) },
    qr/The first argument in the 2-arg constructor must be a hashref or an arrayref/,
    "Only hashref and arrayref are accepted"
);

done_testing;
