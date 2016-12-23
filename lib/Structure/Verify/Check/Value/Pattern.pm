package Structure::Verify::Check::Value::Pattern;
use strict;
use warnings;

use parent 'Structure::Verify::Check::Value';
use Structure::Verify::HashBase;
use Structure::Verify::Behavior::Negatable;

use Structure::Verify::Util::Ref qw/rtype/;

sub operator { $_[0]->negate ? '!~' : '=~' }

sub init {
    my $self = shift;

    croak "'value' must be a regular expression"
        unless rtype($self->{+VALUE}) eq 'REGEXP';
}

sub verify {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $self->SUPER::verify(@_);
    return 0 unless $got->exists;
    return 0 unless $got->defined;

    my ($pass, $fail) = $self->negate ? (0, 1) : (1, 0);
    return $got->value =~ $self->value ? $pass : $fail;
}

1;
