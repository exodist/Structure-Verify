use Test2::Tools::Tiny;
use strict;
use warnings;

use Structure::Verify::Meta;

ok(Structure::Verify::Meta->can($_), "can $_\()") for qw/package builds/;

ok(!__PACKAGE__->can('STRUCTURE_VERIFY'), "no meta yet");
my $meta = Structure::Verify::Meta->new(__PACKAGE__);
is(__PACKAGE__->STRUCTURE_VERIFY, $meta, "Meta added to stash");

is(
    __PACKAGE__->STRUCTURE_VERIFY,
    __PACKAGE__->STRUCTURE_VERIFY,
    "Always the same reference"
);

is($meta->package, __PACKAGE__, "set package");
is_deeply($meta->builds, [], "no builds");

is($meta->current_build, undef, "no current build");

push @{$meta->builds} => qw/a b c/;
is($meta->current_build, 'c', "Last build is latest build");
@{$meta->builds} = ();

done_testing;
