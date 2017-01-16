use strict;
use warnings;
BEGIN { require 't/is.pm'; is->import }

my $CLASS = 'Structure::Verify::Check';
use ok 'Structure::Verify::Check';

use Structure::Verify::Builders qw/exact_ref($)/;

{

    package Fake::Check;
    use base 'Structure::Verify::Check';
    use Structure::Verify::HashBase qw/-value/;

    our $SHOW_ADDRESS = 0;
    sub SHOW_ADDRESS { $SHOW_ADDRESS }

    package XXX;
    use overload '""' => sub { "XxX" };
}

ok($CLASS->can($_), "The '$_' method is defined") for qw/file lines/;

ok(!$CLASS->SHOW_ADDRESS, "Do not show memory addresses by default");

like(
    exception { $CLASS->operator },
    qr/$CLASS does not implement operator\(\)/,
    "No operator"
);

is([$CLASS->verify_meta],    [undef], "verify_meta defaults to undef");
is([$CLASS->verify_simple],  [undef], "verify_simple defaults to undef");
is([$CLASS->verify_complex], [undef], "verify_complex defaults to undef");
is([$CLASS->subchecks],      [],      "subchecks defaults to an empty list");

tests simple => sub {
    my $one = $CLASS->new(lines => [1, 2, 3]);
    is([$one->lines], [1, 2, 3], "got lines");

    my $two = $one->clone;
    is_deeply($one, $two, "Clone");
    ok($one != $two, "Not the same ref");
};

tests build_part1 => sub {
    no warnings 'redefine';

    my %called;
    my $pre_build  = $CLASS->can('pre_build');
    my $post_build = $CLASS->can('post_build');

    local *Structure::Verify::Check::pre_build = sub {
        $called{pre_build}++;
        goto &$pre_build;
    };

    local *Structure::Verify::Check::post_build = sub {
        $called{post_build}++;
        goto &$pre_build;
    };

    %called = ();
    my $x = $CLASS->new;
    is({%called}, {pre_build => 1, post_build => 1}, "Called pre_build and post_build");

    %called = ();
    my $y = $CLASS->new_build;
    is({%called}, {pre_build => 1}, "Called pre_build only");
};

tests build_part2 => sub {
    my $one = bless {}, $CLASS;
    $one->pre_build;
    is($one->building, 1, "is building");
    $one->post_build;
    is($one->building, 0, "done building");

    ok(!$one->build(undef), "Nothing happened");

    like(
        exception { $one->build({}) },
        qr/'$CLASS' does not know how to build with 'HASH/,
        "Cannot build generically with a hash"
    );

    my @args;
    $one->build(sub { @args = @_ }, 'the_alias');
    is(
        \@args,
        [exact_ref($one), 'the_alias'],
        "Got arguments to the build sub"
    );

    my $two = Fake::Check->new_build;
    $two->build('xxx');
    is($two->value, 'xxx', "Set value");

    my $r = qr/xxx/;
    $two = Fake::Check->new_build;
    $two->build($r);
    is($two->value, exact_ref($r), "Can set a regex as value");
};

tests cell => sub {
    my $one  = $CLASS->new();
    my $cell = $one->cell;

    ok($cell->isa('Term::Table::Cell'), "Got a cell");
    is($cell->value,        'CHECK', "Value is 'CHECK'");
    is($cell->border_left,  '>',     "left arrow");
    is($cell->border_right, '<',     "right arrow");

    my $two = Fake::Check->new();
    $cell = $two->cell;
    ok($cell->isa('Term::Table::Cell'), "Got a cell");
    is($cell->value,        'NOT DEFINED', "Value is 'NOT DEFINED'");
    is($cell->border_left,  '>',           "left arrow");
    is($cell->border_right, '<',           "right arrow");

    my $three = Fake::Check->new(value => 'xxx');
    $cell = $three->cell;
    ok($cell->isa('Term::Table::Cell'), "Got a cell");
    is($cell->value, 'xxx', "Value is 'xxx'");
    ok(!$cell->border_left,  "no left arrow");
    ok(!$cell->border_right, "no right arrow");

    my $r = qr/xxx/;
    my $four = Fake::Check->new(value => $r);
    $cell = $four->cell;
    ok($cell->isa('Term::Table::Cell'), "Got a cell");
    is($cell->value,        "$r", "Value is '$r'");
    is($cell->border_left,  '>',  "left arrow");
    is($cell->border_right, '<',  "right arrow");

    my $it = bless({}, 'XXX');

    $Fake::Check::SHOW_ADDRESS = 0;
    my $five = Fake::Check->new(value => $it);
    $cell = $five->cell;
    ok($cell->isa('Term::Table::CellStack'), "Got a cellstack");
    like($cell->cells->[0]->value, qr/^XXX=HASH\Q(...)\E$/, "Value is 'Types and ...'");
    is($cell->cells->[0]->border_left,  '>',   "left arrow");
    is($cell->cells->[0]->border_right, '<',   "right arrow");
    is($cell->cells->[1]->value,        "XxX", "Value is 'XxX'");
    is($cell->cells->[1]->border_left,  ' ',   "left border pad");
    is($cell->cells->[1]->border_right, ' ',   "right border pad");

    $Fake::Check::SHOW_ADDRESS = 1;
    my $six = Fake::Check->new(value => $it);
    $cell = $six->cell;
    ok($cell->isa('Term::Table::CellStack'), "Got a cellstack");
    like($cell->cells->[0]->value, qr/^XXX=HASH\(0x.+\)$/, "Value is 'the address'");
    is($cell->cells->[0]->border_left,  '>',   "left arrow");
    is($cell->cells->[0]->border_right, '<',   "right arrow");
    is($cell->cells->[1]->value,        "XxX", "Value is 'XxX'");
    is($cell->cells->[1]->border_left,  ' ',   "left border pad");
    is($cell->cells->[1]->border_right, ' ',   "right border pad");
};

done_testing;
