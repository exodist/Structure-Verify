package Structure::Verify::Builders;
use strict;
use warnings;

use Structure::Verify::Util::Ref qw/rtype/;
use Structure::Verify::Meta;
use Structure::Verify;

use Carp qw/croak/;

sub import {
    my $class = shift;
    my $caller = caller;

    my $meta = Structure::Verify::Meta->new($caller);

    my (@plain, @named);
    while (@_) {
        my $check = shift;

        if (rtype($_[0]) eq 'HASH') {
            my $hash = shift;
            my $name = $hash->{-as} or croak "no '-as' key present in hash following '$check'";
            push @named => ($check => $name);
        }
        else {
            push @plain => $check;
        }
    }

    my @spec = $meta->load(@plain);
    push @spec => $meta->load_as(@named);

    while (@spec) {
        my $name = shift @spec;
        my $mod  = shift @spec;

        no strict 'refs';
        *{"$caller\::$name"} = sub(&) {
            my @caller = caller(0);
            Structure::Verify::_build(\@caller, $name, $_[0]);
        };
    }
}



1;
