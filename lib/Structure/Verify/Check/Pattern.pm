package Structure::Verify::Check::Pattern;
use strict;
use warnings;

use Structure::Verify::CheckMaker;
use Structure::Verify::HashBase qw/-value/;

use Carp qw/croak/;
use Structure::Verify::Util::Ref qw/rtype/;

sub not_operator { '!~' }
sub operator     { '=~' }

sub post_build {
    my $self = shift;

    $self->SUPER::post_build();

    croak "'value' must be a regular expression (got: $self->{+VALUE})"
        unless rtype($self->{+VALUE}) eq 'REGEXP';
}

sub verify_meta {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $got->exists;
    return 0 unless $got->defined;
    return 1;
}

sub verify_simple {
    my $self = shift;
    my ($got) = @_;

    return $got->value =~ $self->value ? 1 : 0;
}

1;
