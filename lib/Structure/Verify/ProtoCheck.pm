package Structure::Verify::ProtoCheck;
use strict;
use warnings;

use Structure::Verify::Check;

use Structure::Verify::HashBase qw/-lines -file -raw/;

use Carp qw/croak/;

sub init {
    my $self = shift;

    croak "You must provide a raw value for the ProtoCheck"
        unless exists $self->{+RAW};

    unless ($self->{+LINES} && $self->{+FILE}) {
        my @caller = Structure::Verify::Check::trace(
            'Structure::Verify::Check',
            'Structure::Verify::HashBase',
            __PACKAGE__,
        ) or return;

        $self->{+FILE}  ||= $caller[1];
        $self->{+LINES} ||= [$caller[2]];
    }
}

1;
