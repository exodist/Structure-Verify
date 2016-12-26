package Structure::Verify::Check::Stem;
use strict;
use warnings;

use parent 'Structure::Verify::Check';
use Structure::Verify::HashBase qw/-stem/;

use Carp qw/croak/;

sub init {
    my $self = shift;

    $self->SUPER::init();

    return if $self->via_build;

    croak "The 'stem' check must have a 'stem' element"
        unless exists $self->{+STEM};
}

sub cell {
    my $self = shift;

    return Term::Table::Cell->new(
        value        => "<" . $self->{+STEM} . ">",
        border_left  => '>',
        border_right => '<',
    );
}

1;
