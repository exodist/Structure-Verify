use Test2::Tools::Tiny;
use strict;
use warnings;

use Structure::Verify ':ALL';
use Structure::Verify::Convert qw/convert/;
use Structure::Verify::Builders qw/Bag/;
use List::Util qw/shuffle/;

my $c = sub { convert($_[0], {use_regex => 1}) };

my ($bool, $delta) = run_checks(
    [shuffle qw/ foo bar baz /],
    bag {
        check $_ for shuffle qw/ foo bar baz /;
        check 2 => qr/a/;
        end;
    },
    convert => $c,
);

ok($bool, "Pass") || diag map {"$_\n"} $delta->term_table(table_args => {max_width => 80})->render;

($bool, $delta) = run_checks(
    [qw/ x y z a foo bar baz /],
    bag {
        check 'foo';
        check 'bar';
        check 'baz';
        check 2 => qr/a/;
        end;
    },
    convert => $c,
);

ok(!$bool, "Extras");

use Data::Dumper;
print Dumper($delta);

diag map {"$_\n"} $delta->term_table(table_args => {max_width => 80})->render;


done_testing;
