use strict;
use warnings;
BEGIN { require 't/is.pm'; is->import }

use Structure::Verify::Builders(
    qw{ any all one none },
    all => {-as => 'build_all'},
);

ok(__PACKAGE__->can($_), "Imported $_") for qw /hash array bag object any all one none build_all/;

die "Needs more testing, test prototypes";

done_testing;
