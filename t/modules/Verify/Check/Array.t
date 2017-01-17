use strict;
use warnings;
BEGIN { require 't/is.pm'; is->import }

my $CLASS = 'Structure::Verify::Check::Array';
use ok 'Structure::Verify::Check::Array';

use Structure::Verify::Check::Truthy;

is($CLASS->operator,     'IS',     "Operator");
is($CLASS->not_operator, 'IS NOT', "Negative Operator");

tests pre_build => sub {
    my $one = $CLASS->new_build();
    is($one->idx, 0, "set idx to 0");
    is($one->components, [], "Components set to an empty array");
};

tests add_subcheck => sub {
    my $one = $CLASS->new_build();
    $one->add_subcheck('foo');
    $one->add_subcheck('foo');
    $one->add_subcheck(4 => 'bar');
    $one->add_subcheck(4 => 'bar');
    $one->add_subcheck('baz');
    $one->add_subcheck('baz');
    $one->add_subcheck(1 => 'bat');
    $one->add_subcheck('bat');

    like(
        exception { $one->add_subcheck(f => 'bad') },
        qr/Index must be an integer, 'f' does not look like an integer as conversion yields '0'/,
        "Need a valid index"
    );

    is(
        $one->components,
        [
            [0, 'foo'],
            [1, 'foo'],
            [4, 'bar'],
            [4, 'bar'],
            [5, 'baz'],
            [6, 'baz'],
            [1, 'bat'],
            [7, 'bat'],
        ],
        "Index management"
    );
};

tests build => sub {
    my $one = $CLASS->new_build();

    my $meta = Structure::Verify::Meta->new(__PACKAGE__);
    push @{$meta->builds} => $one;
    $one->build(sub {
        check 'foo';
        etc;
    });
    pop @{$meta->builds};

    is(
        $one,
        object {
            check components => [
                [0, Structure::Verify::Check::Truthy->new(true => 1)],
            ];
            check bounded => 0;
            check idx => 1;
        },
        "Defined the state via function"
    );

    my $two = $CLASS->new_build();
    push @{$meta->builds} => $two;
    $two->build(['foo']);
    pop @{$meta->builds};
    is(
        $two,
        object {
            check components => [[0, 'foo']];
            check bounded => undef;
            check idx => 1;
        },
        "Defined the state via array ref"
    );

    my $three = $CLASS->new_build();
    push @{$meta->builds} => $three;
    $three->build({2 => 'foo'});
    pop @{$meta->builds};
    is(
        $three,
        object {
            check components => [[2, 'foo']];
            check bounded => undef;
            check idx => 3;
        },
        "Defined the state via hash ref"
    );
};

tests verify_meta => sub {
    my $one = $CLASS->new_build;
    $one->build([qw/a b c/]);

    my $got = Structure::Verify::Got->from_return([]);
    is($one->verify_meta($got), 1, "Got an arrayref, thats what we want");

    $got = Structure::Verify::Got->from_return();
    is($one->verify_meta($got), 0, "Got nothing, thats not what we want");

    $got = Structure::Verify::Got->from_return(undef);
    is($one->verify_meta($got), 0, "Got undef, thats not what we want");

    $got = Structure::Verify::Got->from_return('foo');
    is($one->verify_meta($got), 0, "Got a scalar, thats not what we want");

    $got = Structure::Verify::Got->from_return({});
    is($one->verify_meta($got), 0, "Got a hashref, thats not what we want");
};

tests cell => sub {
    my $one  = $CLASS->new;
    my $cell = $CLASS->cell;
    is($cell->value,        'ArrayRef', "cell value is ArrayRef");
    is($cell->border_left,  '>',        "left border");
    is($cell->border_right, '<',        "right border");
};

tests subchecks => sub {
    my $one = $CLASS->new_build;
    $one->build([qw/a b c/]);

    my $got = Structure::Verify::Got->from_return([qw/a c/]);

    is(
        [$one->subchecks('PATH', $got)],
        [
            ['PATH[0]', 'a', object { -isa => 'Structure::Verify::Got', check value => 'a' }],
            ['PATH[1]', 'b', object { -isa => 'Structure::Verify::Got', check value => 'c' }],
            ['PATH[2]', 'c', object { -isa => 'Structure::Verify::Got', check value => undef }],
        ],
        "Got subchecks"
    );

    my $two = $CLASS->new_build;
    $two->build([qw/a b c/]);
    $two->set_bounded(1);

    $got = Structure::Verify::Got->from_return([qw/a c c d/]);

    is(
        [$two->subchecks('PATH', $got)],
        [
            ['PATH[0]', 'a', object { -isa => 'Structure::Verify::Got', check value => 'a' }],
            ['PATH[1]', 'b', object { -isa => 'Structure::Verify::Got', check value => 'c' }],
            ['PATH[2]', 'c', object { -isa => 'Structure::Verify::Got', check value => 'c' }],
            [
                'PATH[3]',
                object { -isa => 'Structure::Verify::Check::Boundary' },
                object { -isa => 'Structure::Verify::Got', check value => 'd' },
            ],
        ],
        "Got subchecks"
    );

};

done_testing;
