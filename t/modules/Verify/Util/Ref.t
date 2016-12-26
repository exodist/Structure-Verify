use Test2::Tools::Tiny;
use strict;
use warnings;

use Structure::Verify::Util::Ref qw/rtype render_ref/;

ok(__PACKAGE__->can($_), "imported $_\()") for qw{ render_ref rtype };

{
    package Test::A;
    package Test::B;
    use overload '""' => sub { 'A Bee!' };
}
my $ref = {a => 1};
is(render_ref($ref), "$ref", "Matches normal stringification (not blessed)");
like(render_ref($ref), qr/HASH\(0x[0-9A-F]+\)/i, "got address");

bless($ref, 'Test::A');
is(render_ref($ref), "$ref", "Matches normal stringification (blessed)");
like(render_ref($ref), qr/Test::A=HASH\(0x[0-9A-F]+\)/i, "got address and package (no overload)");

bless($ref, 'Test::B');
like(render_ref($ref), qr/Test::B=HASH\(0x[0-9A-F]+\)/i, "got address and package (with overload)");

my $x = '';
$ref = \$x;
is(rtype(undef),     '',       "not a ref");
is(rtype(''),        '',       "not a ref");
is(rtype({}),        'HASH',   "HASH");
is(rtype([]),        'ARRAY',  "ARRAY");
is(rtype($ref),      'SCALAR', "SCALAR");
is(rtype(\$ref),     'REF',    "REF");
is(rtype(sub { 1 }), 'CODE',   "CODE");
is(rtype(qr/xxx/),   'REGEXP', "REGEXP");

done_testing;
