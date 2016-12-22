package Structure::Verify::Check::Value;
use strict;
use warnings;

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use Structure::Verify::Util::Ref qw/render_ref/;

use parent 'Structure::Verify::Check';
use Structure::Verify::HashBase qw/-value/;

sub verify {
    my $self = shift;
    my ($got) = @_;

    croak "verify() requires a 'Structure::Verify::Got' instance as the only argument"
        unless $got && $got->isa('Structure::Verify::Got');

    1;
}

sub cell {
    my $self = shift;

    my $value = $self->value;

    return Term::Table::Cell->new(
        value        => 'NOT DEFINED',
        border_left  => '>',
        border_right => '<',
    ) unless defined $value;

    if(ref($value)) {
        my $refa = render_ref($value);
        my $refb = "" . $value;

        my $val_string = $refa;
        $val_string .= "\n$refb" if $refa ne $refb;

        return Term::Table::Cell->new(
            value => $val_string,
            border_left  => '>',
            border_right => '<',
        );
    }

    return Term::Table::Cell->new(
        value => "$value",
    );
}

1;
