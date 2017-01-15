package Structure::Verify::Check::Ref;
use strict;
use warnings;

use parent 'Structure::Verify::Check';

use Structure::Verify::HashBase qw/-type -subcheck/;

use Structure::Verify::Util::Ref qw/rtype/;
use Carp qw/croak/;

use Structure::Verify::Got;
use Term::Table::Cell;

my %SUBCHECK = (
    SCALAR => 1,
    REF    => 1,
);

sub operator { 'IS' }

sub cell {
    return Term::Table::Cell->new(
        value        => 'Ref',
        border_left  => '>',
        border_right => '<',
    );
}

sub build {
    my $self = shift;
    my ($with, $alias) = @_;

    my $rtype = rtype($with);

    return $self->{+TYPE} = $with
        unless $rtype;

    if ($SUBCHECK{$rtype}) {
        $self->{+TYPE} = 'subcheck';
        $self->{+SUBCHECK} = $$with;
        return;
    }

    return $self->SUPER::build(@_);
}

sub init {
    my $self = shift;

    $self->SUPER::init();
    return if $self->{+VIA_BUILD};

    my $type = $self->{+TYPE}
        or croak "'type' is required";

    croak "Type '$type' is not allowed to have subchecks"
        if $self->{+SUBCHECK} && $type ne 'subcheck';
}

sub verify {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $got->exists;
    return 0 unless $got->defined;

    my $value = $got->value or return 0;
    my $type = rtype($value);

    return 1 if $type eq $self->{+TYPE};
    return 1 if $self->{+TYPE} eq 'subcheck' && $SUBCHECK{$type};

    return 0;
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

sub add_subcheck {
    my $self = shift;
    my ($check, $extra) = @_;

    croak "Too many arguments"
        if $extra;

    croak "Subcheck already set"
        if $self->{+SUBCHECK};

    $self->{+SUBCHECK} = $check;
}

1;

