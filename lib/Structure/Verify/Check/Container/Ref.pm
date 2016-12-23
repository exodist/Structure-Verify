package Structure::Verify::Check::Container::Ref;
use strict;
use warnings;

use parent 'Structure::Verify::Check::Container';

use Structure::Verify::HashBase qw/-type -subcheck/;

use Structure::Verify::Util::Ref qw/rtype/;
use Scalar::Util qw/blessed/;
use Carp qw/croak/;

use Structure::Verify::Got;
use Term::Table::Cell;

sub operator { 'IS' }

sub cell {
    return Term::Table::Cell->new(
        value        => 'Ref',
        border_left  => '>',
        border_right => '<',
    );
}

sub init {
    my $self = shift;

    my $type = $self->{+TYPE}
        or croak "'type' is required";

    croak "Type '$type' is not allowed to have subchecks"
        if $self->{+SUBCHECK} && $type !~ m/^(SCALAR|REF)$/;
}

sub verify {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $got->exists;
    return 0 unless $got->defined;

    my $value = $got->value or return 0;
    return 0 unless rtype($value) eq $self->{+TYPE};
    return 1;
}

sub subchecks {
    my $self = shift;
    my ($path, $got) = @_;

    my $check = $self->{+SUBCHECK} or return;

    my $type  = $self->{+TYPE};
    my $value = $got->value;

    return (
        ["$path\->\$*", $check, Structure::Verify::Got->from_return(${$value})],
    );
}

1;

