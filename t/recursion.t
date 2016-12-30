use Test2::Tools::Tiny;
use strict;
use warnings;

use Test2::API qw/context/;

use Structure::Verify ':ALL';
use Structure::Verify::Builders(
    qw{ Hash Array },
);

use Structure::Verify::Convert qw/convert/;

my $c = sub { convert($_[0], $_[1], {use_regex => 1}) };

my $thing1 = {
    a => 1,
    b => 1,
};
$thing1->{c} = $thing1;

my $thing2 = {
    a => 1,
    b => 1,
};
$thing2->{c} = $thing2;

my ($bool, $delta) = run_checks(
    $thing1, $thing2,
    convert => $c,
);

ok($bool, "Checks passed") || diag map {"$_\n"} $delta->term_table(table_args => {max_width => 80})->render;

done_testing;
