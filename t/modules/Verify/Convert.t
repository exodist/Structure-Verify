use strict;
use warnings;
BEGIN { require 't/is.pm'; is->import }

use Structure::Verify::ProtoCheck;

my $CLASS = 'Structure::Verify::Convert';

use Structure::Verify::Convert ':ALL';
ok(__PACKAGE__->can($_), "imported $_") for qw/convert basic_convert relaxed_convert strict_convert/;

tests convert_from_check => sub {
    my $state = {};
    my $array = array {
        check 0 => 'a';
        check 1 => 'b';
        check 'c';
    };

    my ($got, $gs) = convert($array, $state, {});
    ok($got == $array, "Passed through as-is");
    ok($gs == $state, "State is not modified");

    ($got, $gs) = convert($array, $state, {implicit_end => 1});
    ok($got != $array, "Did not get original");
    ok($gs == $state, "State is not modified");
    is_deeply(
        { %$array, bounded => 'implicit' },
        { %$got },
        "Cloned, but now bounded is set to true"
    );

    $array->set_bounded(0);
    ($got, $gs) = convert($array, $state, {implicit_end => 1});
    ok($got == $array, "Passed through as-is, bound is already defined");
    ok($gs == $state, "State is not modified");
};

tests convert_from_protocheck => sub {
    my $state = {};
    my $proto = Structure::Verify::ProtoCheck->new(
        file => 'foo.t',
        lines => [1, 3],
        raw => 'apple',
    );

    my ($got, $gs) = convert($proto, $state, {});
    ok($got->isa('Structure::Verify::Check::String'), "Converted to check");
    is($got->file, 'foo.t', "got the file");
    is([$got->lines], [1, 3], "Got the lines");
    is($got->value, 'apple', "Value carried over");
};

tests no_params => sub {
    my ($check) = convert(1, {}, {});
    ok($check->isa('Structure::Verify::Check::String'), "Numbers are strings");

    ($check) = convert("abc", {}, {});
    ok($check->isa('Structure::Verify::Check::String'), "Strings are strings");

    ($check) = convert(qr/xxx/, {}, {});
    ok($check->isa('Structure::Verify::Check::ExactRef'), "Exact ref for regex");

    ($check) = convert(v1.2.3, {}, {});
    ok($check->isa('Structure::Verify::Check::VString'), "VString type");

    ($check) = convert({}, {}, {});
    ok($check->isa('Structure::Verify::Check::Hash'), "Made a hash");
    is($check->bounded, 0, "Not bounded");

    ($check) = convert([], {}, {});
    ok($check->isa('Structure::Verify::Check::Array'), "Made a array");
    is($check->bounded, 0, "Not bounded");

    ($check) = convert(\"x", {}, {});
    ok($check->isa('Structure::Verify::Check::Ref'), "Made a ref");

    ($check) = convert(sub { 1 }, {}, {});
    ok($check->isa('Structure::Verify::Check::ExactRef'), "Made an exactref");
};

tests implicit_end => sub {
    my ($check) = convert({}, {}, {implicit_end => 1});
    ok($check->isa('Structure::Verify::Check::Hash'), "Made a hash");
    is($check->bounded, 1, "Not bounded");

    ($check) = convert([], {}, {implicit_end => 1});
    ok($check->isa('Structure::Verify::Check::Array'), "Made a array");
    is($check->bounded, 1, "Not bounded");
};

tests use_regex => sub {
    my ($check) = convert(qr/xxx/, {}, {use_regex => 1});
    ok($check->isa('Structure::Verify::Check::Pattern'), "Use Regex as pattern");
};

tests use_code => sub {
    my ($check) = convert(sub { 1 }, {}, {use_code => 1});
    ok($check->isa('Structure::Verify::Check::Custom'), "Use sub as custom");
};

done_testing;
