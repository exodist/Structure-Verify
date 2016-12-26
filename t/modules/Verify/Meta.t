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

$meta->load(qw/String Hash Bag/);
ok($INC{'Structure/Verify/Check/Value/String.pm'}, "Loaded string");
ok($INC{'Structure/Verify/Check/Container/Hash.pm'}, "Loaded hash");
ok($INC{'Structure/Verify/Check/Bag.pm'}, "Loaded bag");
is_deeply(
    $meta->build_map,
    {
        string => 'Structure::Verify::Check::Value::String',
        hash   => 'Structure::Verify::Check::Container::Hash',
        bag    => 'Structure::Verify::Check::Bag',
    },
    "Build map",
);

$meta->load_as(
    Array    => 'ar',
    Boundary => 'bo',
    Pattern  => 'pt',
    Regex    => 'number'
);
ok($INC{'Structure/Verify/Check/Value/Pattern.pm'},   "Loaded pattern");
ok($INC{'Structure/Verify/Check/Container/Array.pm'}, "Loaded array");
ok($INC{'Structure/Verify/Check/Boundary.pm'},        "Loaded boundary");
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

my $warnings = warnings { $meta->load('Number') };
like(
    $warnings->[0],
    qr/check short name 'number' was set to 'Structure::Verify::Check::Value::Regex' but is being reset to 'Structure::Verify::Check::Value::Number'/,
    "Redefined 'number'"
);

$warnings = warnings { $meta->load_as('Regex' => 'number') };
like(
    $warnings->[0],
    qr/check short name 'number' was set to 'Structure::Verify::Check::Value::Number' but is being reset to 'Structure::Verify::Check::Value::Regex'/,
    "Redefined 'number' again"
);

like(
    exception { $meta->load('123Fake-.!~') },
    qr/\QCould not find check 123Fake-.!~\E/,
    "Cannot find fake check"
);

like(
    exception { local @INC = ('t/lib', 'lib'); $meta->load('+Broken') },
    qr/^oops at/,
    "Exception in broken check code propogated"
);

done_testing;
