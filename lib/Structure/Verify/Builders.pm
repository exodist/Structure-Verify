package Structure::Verify::Builders;
use strict;
use warnings;

use Carp qw/croak/;
use Structure::Verify::Util::Ref qw/rtype/;

use Structure::Verify::Meta;
use Structure::Verify;

$Carp::Internal{ (__PACKAGE__) }++;

sub import {
    my $class = shift;
    my $caller = caller;

    while (@_) {
        my $build = shift;

        my $name = $build;
        if (rtype($_[0]) eq 'HASH') {
            my $spec = shift;

            $name = $spec->{'-as'}
                or croak "Missing '-as' key in import specification hash"
        }

        no strict 'refs';
        *{"$caller\::$name"} = sub(&) {
            my @caller = caller(0);
            Structure::Verify::_build(\@caller, $build, $_[0]);
        };
    }
}

1;
