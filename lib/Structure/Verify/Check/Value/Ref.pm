package Structure::Verify::Check::Value::Ref;
use strict;
use warnings;

use parent 'Structure::Verify::Check::Value';
use Structure::Verify::HashBase;

use Scalar::Util qw/refaddr/;
use Structure::Verify::Util::Ref qw/rtype/;

sub operator { 'IS' }
sub negative_operator { 'IS NOT' }

sub init {
    my $self = shift;

    croak "'value' must be a reference"
        unless ref($self->{+VALUE});
}

sub verify {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $self->SUPER::verify(@_);
    return 0 unless $got->exists;
    return 0 unless $got->defined;
    return 0 unless ref($got->value);
    return 0 unless rtype($got->value) eq rtype($self->value);
    return 0 unless refaddr($got->value) == refaddr($self->value);
    return 1;
}

1;
