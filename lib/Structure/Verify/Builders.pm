package Structure::Verify::Builders;
use strict;
use warnings;

use Structure::Verify::Util::Ref qw/rtype/;
use Structure::Verify::Meta;
use Structure::Verify;

$Carp::Internal{ (__PACKAGE__) }++;

sub import {
    my $class = shift;
    my $caller = caller;

    while (@_) {
        my $build = shift;
        my $spec = rtype($_[0]) eq 'HASH' ? shift : undef;
        my $name = $spec ? $spec->{'-as'} || $build : $build;

        no strict 'refs';
        *{"$caller\::$name"} = sub(&) {
            my @caller = caller(0);
            Structure::Verify::_build(\@caller, $build, $_[0]);
        };
    }
}

1;
