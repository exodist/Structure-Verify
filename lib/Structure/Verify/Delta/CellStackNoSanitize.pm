package Structure::Verify::Delta::CellStackNoSanitize;
use strict;
use warnings;

use parent 'Term::Table::CellStack';

sub sanitize  { 1 }
sub mark_tail { 1 }

1;
