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
        my $build = shift;

        if (rtype($_[0]) eq 'HASH') {
            my $spec = shift;

            my $name = $spec->{'-as'}
                or croak "Missing '-as' key in import specification hash";

            $class->build_sub($caller, $build, $name);
        }
        elsif (rtype($_[0]) eq 'ARRAY') {
            my $list = shift;
            $class->build_sub($caller, $build, $_) for @$list
        }
        else {
            $class->build_sub($caller, $build, $build);
        }
    }
}

sub build_sub {
    my $class = shift;
    my ($caller, $build, $name) = @_;

    $build =~ s/(\(.*\))$//;    # Remove any prototype from the build
    my $default_proto = $1 || '(&)';

    $name =~ s/(\(.*\))$//;     # Remove any prototype from the name
    my $proto = $1 || $default_proto;

    my $file = __FILE__;
    my $line = __LINE__ + 2;
    eval <<"    EOT" or die $@;
#line $line "$file"
sub ${caller}::${name}${proto} {
    my \@caller = caller(0);
    Structure::Verify::_build(\\\@caller, \$build, \$_[0]);
};

1;
    EOT
}

1;
