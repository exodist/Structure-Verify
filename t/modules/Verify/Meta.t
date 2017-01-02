use Test2::Tools::Tiny;
use strict;
use warnings;

use Structure::Verify::Meta;

ok(Structure::Verify::Meta->can($_), "can $_\()") for qw/package build_map builds/;

ok(!__PACKAGE__->can('STRUCTURE_VERIFY'), "no meta yet");
my $meta = Structure::Verify::Meta->new(__PACKAGE__);
is(__PACKAGE__->STRUCTURE_VERIFY, $meta, "Meta added to stash");

is(
    __PACKAGE__->STRUCTURE_VERIFY,
    __PACKAGE__->STRUCTURE_VERIFY,
    "Always the same reference"
);

is_deeply($meta->build_map, {}, "empty build map");
is($meta->package, __PACKAGE__, "set package");
is_deeply($meta->builds, [], "no builds");

is($meta->current_build, undef, "no current build");

push @{$meta->builds} => qw/a b c/;
is($meta->current_build, 'c', "Last build is latest build");
@{$meta->builds} = ();

require Structure::Verify::Check::Value::String;
require Structure::Verify::Check::Container::Hash;
require Structure::Verify::Check::Bag;
Structure::Verify::Check::Value::String->import;
Structure::Verify::Check::Container::Hash->import;
Structure::Verify::Check::Bag->import;

is_deeply(
    $meta->build_map,
    {
        string => 'Structure::Verify::Check::Value::String',
        hash   => 'Structure::Verify::Check::Container::Hash',
        bag    => 'Structure::Verify::Check::Bag',
    },
    "Build map",
);

require Structure::Verify::Check::Container::Array;
require Structure::Verify::Check::Value::Pattern;
require Structure::Verify::Check::Value::Regex;
require Structure::Verify::Check::Boundary;
Structure::Verify::Check::Container::Array->import('ar');
Structure::Verify::Check::Value::Pattern->import('pt');
Structure::Verify::Check::Value::Regex->import('number');
Structure::Verify::Check::Boundary->import('bo');

is_deeply(
    $meta->build_map,
    {
        string => 'Structure::Verify::Check::Value::String',
        hash   => 'Structure::Verify::Check::Container::Hash',
        bag    => 'Structure::Verify::Check::Bag',

        ar => 'Structure::Verify::Check::Container::Array',
        pt => 'Structure::Verify::Check::Value::Pattern',
        bo => 'Structure::Verify::Check::Boundary',

        number => 'Structure::Verify::Check::Value::Regex',
    },
    "Build map",
);

my $warnings = warnings {
    require Structure::Verify::Check::Value::Number;
    Structure::Verify::Check::Value::Number->import;
};
like(
    $warnings->[0],
    qr/check short name 'number' was set to 'Structure::Verify::Check::Value::Regex' but is being reset to 'Structure::Verify::Check::Value::Number'/,
    "Redefined 'number'"
);

done_testing;
