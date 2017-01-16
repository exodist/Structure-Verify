package Structure::Verify::Builders;
use strict;
use warnings;

use Carp qw/croak/;
use Structure::Verify::Util::Ref qw/rtype/;

use Structure::Verify::Meta;
use Structure::Verify;

$Carp::Internal{ (__PACKAGE__) }++;

sub import {
    my $class  = shift;
    my $caller = caller;

    while (@_) {
        my $input = shift;

        my $name  = $input;
        my $build = $input;
        if (rtype($_[0]) eq 'HASH') {
            my $spec = shift;

            $name = $spec->{'-as'}
                or croak "Missing '-as' key in import specification hash";
        }

        $build =~ s/(\(.*\))$//;    # Remove any prototype from the build
        my $default_proto = $1 || '(&)';

        $name =~ s/(\(.*\))$//;     # Remove any prototype from the name
        my $proto = $1 || $default_proto;

        no strict 'refs';
        *{"$caller\::$name"} = eval "sub$proto" . ' {
            my @caller = caller(0);
            Structure::Verify::_build(\@caller, $build, $_[0]);
        }' or die $@;
    }
}

1;
