package Structure::Verify::CheckMaker;
use strict;
use warnings;

require overload;
require Structure::Verify::HashBase;
require Structure::Verify::Check;

sub import {
    my $class = shift;
    my ($base) = @_;

    $base ||= 'Structure::Verify::Check';

    my ($pkg, $file, $line) = caller;

    my $sub = eval <<"    EOT" or die $@;
package $pkg;
#line $line "$file"
sub { overload->import('!' => 'negate', fallback => 1); push \@$pkg\::ISA => \$base; Structure::Verify::HashBase->import()}
    EOT

    $sub->();
}

1;
