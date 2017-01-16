package Structure::Verify::Check::Regex;
use strict;
use warnings;

use Structure::Verify::CheckMaker;
use Structure::Verify::HashBase qw/-value/;

use Carp qw/croak/;
use Structure::Verify::Util::Ref qw/rtype/;

sub not_operator { 'IS NOT' }
sub operator     { 'IS' }

sub post_build {
    my $self = shift;

    $self->SUPER::post_build();

    croak "'value' must be a regular expression"
        unless rtype($self->{+VALUE}) eq 'REGEXP';
}

sub verify_type {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $got->exists;
    return 0 unless $got->defined;

    return 0 unless rtype($got->value) eq 'REGEXP';
    return 1;
}

sub verify {
    my $self = shift;
    my ($got) = @_;

    my $got_val  = $got->value;
    my $want_val = $self->value;

    return "$got_val" eq "$want_val" ? 1 : 0;
}

1;
