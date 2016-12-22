package Structure::Verify::Check::Container;
use strict;
use warnings;

use parent 'Structure::Verify::Check';
use Structure::Verify::HashBase;

sub add_subcheck { croak blessed($_[0]) . " does not implement add_subcheck()" }

1;
