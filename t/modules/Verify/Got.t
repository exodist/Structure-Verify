use Test2::Tools::Tiny;
use strict;
use warnings;

use Structure::Verify::Got;
use Structure::Verify qw/build/;
use Structure::Verify::Check::String;

my $CLASS = 'Structure::Verify::Got';

ok($CLASS->can($_), "accessor $_\() present") for qw{exists value defined exception};

my $one;

tests from_value => sub {
    $one = $CLASS->from_return();
    is($one->exists,  0, "it does not exist");
    is($one->defined, 0, "it is not defined");
    is_deeply([$one->value], [], "value return nothing");

    $one = $CLASS->from_return(undef);
    is($one->exists,  1, "it does exist");
    is($one->defined, 0, "it is not defined");
    is_deeply([$one->value], [undef], "value returns undef");

    $one = $CLASS->from_return(0);
    is($one->exists,  1, "it does exist");
    is($one->defined, 1, "it is defined");
    is_deeply([$one->value], [0], "value returns 0");

    $one = $CLASS->from_return('abc');
    is($one->exists,  1, "it does exist");
    is($one->defined, 1, "it is defined");
    is_deeply([$one->value], ['abc'], "value returns 'abc'");

    like(
        exception { $CLASS->from_return(0, 1) },
        qr/Too many arguments provided to the constructor/,
        "Only 0 or 1 args"
    );
};

tests from_hash_key => sub {
    $one = $CLASS->from_hash_key({}, 'a');
    is($one->exists,  0, "it does not exist");
    is($one->defined, 0, "it is not defined");
    is_deeply([$one->value], [], "value return nothing");

    $one = $CLASS->from_hash_key({a => undef}, 'a');
    is($one->exists,  1, "it does exist");
    is($one->defined, 0, "it is not defined");
    is_deeply([$one->value], [undef], "value returns undef");

    $one = $CLASS->from_hash_key({a => 0}, 'a');
    is($one->exists,  1, "it does exist");
    is($one->defined, 1, "it is defined");
    is_deeply([$one->value], [0], "value returns 0");

    $one = $CLASS->from_hash_key({a => 'abc'}, 'a');
    is($one->exists,  1, "it does exist");
    is($one->defined, 1, "it is defined");
    is_deeply([$one->value], ['abc'], "value returns 'abc'");

    like(
        exception { $CLASS->from_hash_key(0) },
        qr/First argument must be a hashref/,
        "First arg must be a hash"
    );

    like(
        exception { $CLASS->from_hash_key({}) },
        qr/The second argument must be defined/,
        "Second arg must be defined"
    );
};

tests from_array_idx => sub {
    $one = $CLASS->from_array_idx([], 0);
    is($one->exists,  0, "it does not exist");
    is($one->defined, 0, "it is not defined");
    is_deeply([$one->value], [], "value return nothing");

    $one = $CLASS->from_array_idx([undef], 0);
    is($one->exists,  1, "it does exist");
    is($one->defined, 0, "it is not defined");
    is_deeply([$one->value], [undef], "value returns undef");

    $one = $CLASS->from_array_idx([0], 0);
    is($one->exists,  1, "it does exist");
    is($one->defined, 1, "it is defined");
    is_deeply([$one->value], [0], "value returns 0");

    $one = $CLASS->from_array_idx(['abc'], 0);
    is($one->exists,  1, "it does exist");
    is($one->defined, 1, "it is defined");
    is_deeply([$one->value], ['abc'], "value returns 'abc'");

    like(
        exception { $CLASS->from_array_idx(0) },
        qr/First argument must be an arrayref/,
        "First arg must be an array"
    );

    like(
        exception { $CLASS->from_array_idx([], 'z') },
        qr/The second argument must be an integer/,
        "Second arg must be an integer"
    );
};

tests from_method => sub {
    {
        package TestObj;
        use Structure::Verify::HashBase qw/foo bar baz/;

        sub all_list {
            my $self = shift;

            return (
                foo => $self->{+FOO},
                bar => $self->{+BAR},
                baz => $self->{+BAZ},
            );
        }

        sub all_array {
            my $self = shift;
            my @array = $self->all_list;
            return @array;
        }

        sub want { wantarray ? (1, 2, 3) : 'abc' }

        sub nope { return }
    }

    my $obj = TestObj->new(
        foo => 'foo',
        bar => undef,
        baz => 0
    );

    tests scalar_context => sub {
        $one = $CLASS->from_method($obj, 'all_list');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply([$one->value], [0], "Normal behavior for list return in scalar context, got last value");

        $one = $CLASS->from_method($obj, 'all_array');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply([$one->value], [6], "Normal behavior for array return in scalar context, got count");

        $one = $CLASS->from_method($obj, 'want');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply([$one->value], ['abc'], "Got scalar value");

        $one = $CLASS->from_method($obj, 'nope');
        is($one->exists,  1, "it does exist");
        is($one->defined, 0, "it is not defined");
        is_deeply([$one->value], [undef], "Got scalar value of an empty list (undef)");

        $one = $CLASS->from_method($obj, 'foo');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply([$one->value], ['foo'], "Got simple scalar return");
    };

    tests array_wrap => sub {
        $one = $CLASS->from_method($obj, 'all_list', '@');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply($one->value, [foo => 'foo', bar => undef, baz => 0], "Wrapped in an array");

        $one = $CLASS->from_method($obj, 'all_array', '@');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply($one->value, [foo => 'foo', bar => undef, baz => 0], "Wrapped in an array");

        $one = $CLASS->from_method($obj, 'want', '@');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply($one->value, [1, 2, 3], "Got list");

        $one = $CLASS->from_method($obj, 'nope', '@');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is not defined");
        is_deeply($one->value, [], "Got empty arrayref");

        $one = $CLASS->from_method($obj, 'foo', '@');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply($one->value, ['foo'], "Scalar was wrapped in an array");
    };

    tests hash_wrap => sub {
        $one = $CLASS->from_method($obj, 'all_list', '%');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply($one->value, {foo => 'foo', bar => undef, baz => 0}, "Wrapped in a hash");

        $one = $CLASS->from_method($obj, 'all_array', '%');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply($one->value, {foo => 'foo', bar => undef, baz => 0}, "Wrapped in a hash");

        my $line;
        my $file = __FILE__;

        my $warnings = warnings {
            $line = __LINE__ + 1;
            $one = $CLASS->from_method($obj, 'want', '%', build string => '123');
        };

        like(
            $warnings->[0],
            qr/Odd number of elements in anonymous hash at \Q$file\E \(eval in[^\)]+\) line $line/,
            "Warning reported to the check"
        );

        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply($one->value, {1 => 2, 3 => undef}, "Got list");

        $one = $CLASS->from_method($obj, 'nope', '%');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is not defined");
        is_deeply($one->value, {}, "Got empty hashref");

        $warnings = warnings { $one = $CLASS->from_method($obj, 'foo', '%') };
        like(
            $warnings->[0],
            qr/^Odd number of elements in anonymous hash\.?$/,
            "Not sure where to report warning"
        );

        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply($one->value, {'foo' => undef}, "Scalar was wrapped in a hash");
    };

    tests with_error => sub {
        $one = $CLASS->from_method($obj, 'not_a_method');
        is($one->exists,  0, "it does not exist");
        is($one->defined, 0, "it is not defined");

        is_deeply($one->value, undef, "No value");

        like(
            $one->exception,
            qr/Can't locate object method "not_a_method" via package "TestObj"/,
            "Got exception"
        );
    };
};

tests lines => sub {
    {
        package TestObj2;
        sub structure_verify_lines { (1, 2) }
    }

    my $one = $CLASS->new(value => '');
    my $two = $CLASS->new(value => bless({}, 'TestObj2'));
    ok(!$one->lines, "No Lines when it does not exist");
    ok(!$two->lines, "No Lines when it does not exist");

    $one->{exists} = 1;
    $two->{exists} = 1;
    ok(!$one->lines, "No Lines when it is not defined");
    ok(!$two->lines, "No Lines when it is not defined");

    $one->{defined} = 1;
    $two->{defined} = 1;
    ok(!$one->lines, "No Lines when not blessed");
    is_deeply([$two->lines], [1, 2], "got lines");
};

tests cell => sub {
    my $one = $CLASS->new(exception => 'an exception');
    my $cell = $one->cell;
    is($cell->value,        'Exception: an exception', "Cell has an exception");
    is($cell->border_left,  '>',                       "got left border");
    is($cell->border_right, '<',                       "got right border");

    $one = $CLASS->new(exists => 0);
    $cell = $one->cell;
    is($cell->value,        'DOES NOT EXIST', "value does not exist");
    is($cell->border_left,  '>',              "got left border");
    is($cell->border_right, '<',              "got right border");

    $one = $CLASS->new(exists => 1, defined => 0);
    $cell = $one->cell;
    is($cell->value,        'NOT DEFINED', "value is not defined");
    is($cell->border_left,  '>',           "got left border");
    is($cell->border_right, '<',           "got right border");

    $one = $CLASS->new(exists => 1, defined => 1, value => 'a', meta => 1);
    $cell = $one->cell;
    is($cell->value,        'a', "value is 'a'");
    is($cell->border_left,  '>', "got left border");
    is($cell->border_right, '<', "got right border");

    $one = $CLASS->new(exists => 1, defined => 1, value => 'a', meta => 0);
    $cell = $one->cell;
    is($cell->value, 'a', "value is 'a'");
    ok(!$cell->border_left,  "no left border");
    ok(!$cell->border_right, "no right border");

    $one = $CLASS->new(exists => 1, defined => 1, value => {}, meta => 0);
    $cell = $one->cell;
    is($cell->value, 'HASH(...)', "value is 'HASH(...)'");
    is($cell->border_left,  '>', "got left border");
    is($cell->border_right, '<', "got right border");

    $cell = $one->cell(show_address => 1);
    like($cell->value, qr/^HASH\(0x.*\)$/i, "value is 'HASH(0x...)'");
    is($cell->border_left,  '>', "got left border");
    is($cell->border_right, '<', "got right border");

};

done_testing;
