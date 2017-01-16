use strict;
use warnings;
BEGIN { require 't/is.pm'; is->import }

use Structure::Verify::Builders(
    qw{ any all one none },
    all => {-as => 'build_all'},
    'exact_ref($)',
    exact_ref => { -as => 'this_ref($)' },
    exact_ref => [qw/ a_coderef(&) a_hash(\%) an_array(\@) a_scalar(\$) /],
    'exact_ref($)' => [qw/xxx yyy zzz/],
);

ok(__PACKAGE__->can($_), "Imported $_") for qw{
    hash array bag object any all one none build_all
    exact_ref this_ref a_coderef a_hash an_array a_scalar
    xxx yyy zzz
};

is(prototype(\&build_all), undef, "no default prototype");
is(prototype(\&exact_ref), '$',   "Got specified prototype, no rename");
is(prototype(\&a_coderef), '&',   "specified '&' in alias");
is(prototype(\&a_hash),    '\\%', "specified '\\\%' in alias");
is(prototype(\&an_array),  '\\@', "specified '\\\@' in alias");
is(prototype(\&a_scalar),  '\\$', "specified '\\\$' in alias");
is(prototype(\&xxx),       '$',   "specified '\$' in build, so list defaults to it");
is(prototype(\&yyy),       '$',   "specified '\$' in build, so list defaults to it");
is(prototype(\&zzz),       '$',   "specified '\$' in build, so list defaults to it");

done_testing;
