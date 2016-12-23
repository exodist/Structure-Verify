package Structure::Verify::Behaviors::Negatable;
use strict;
use warnings;

require overload;
require Structure::Verify::HashBase;

sub import {
    my ($pkg, $file, $line) = caller;

    my $sub = eval <<"    EOT" or die $@;
package $pkg;
#line $line "$file"
sub { overload->import('!' => 'clone_negate', fallback => 1); Structure::Verify::HashBase->import('negate')}
    EOT

    $sub->();

    no strict 'refs';
    *{"$pkg\::clone_negate"}  = \&clone_negate;
    *{"$pkg\::toggle_negate"} = \&toggle_negate;
}

sub clone_negate {
    my $self  = shift;
    my $clone = $self->clone;
    $clone->toggle_negate;
    return $clone;
}

sub toggle_negate {
    my $self = shift;
    $self->set_negate($self->negate ? 0 : 1);
}

1;
