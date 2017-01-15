package Structure::Verify::Check::Regex;
use strict;
use warnings;

use parent 'Structure::Verify::Check';
use Structure::Verify::HashBase qw/-value/;
use Structure::Verify::Behaviors::Negatable;

use Carp qw/croak/;
use Structure::Verify::Util::Ref qw/rtype/;

sub operator { $_[0]->negate ? 'IS NOT' : 'IS' }

sub post_build {
    my $self = shift;

    $self->SUPER::post_build();

    croak "'value' must be a regular expression"
        unless rtype($self->{+VALUE}) eq 'REGEXP';
}

sub verify {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $got->exists;
    return 0 unless $got->defined;

    my $got_val  = $got->value;
    my $want_val = $self->value;

    return 0 unless rtype($got->value) eq 'REGEXP';

    my ($pass, $fail) = $self->negate ? (0, 1) : (1, 0);
    return $fail unless "$got_val" eq "$want_val";
    return $pass;
}

1;
