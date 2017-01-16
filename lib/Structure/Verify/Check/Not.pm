package Structure::Verify::Check::Not;
use strict;
use warnings;

use Structure::Verify::CheckMaker;
use Structure::Verify::HashBase qw/-check/;

use Scalar::Util qw/blessed/;
use Carp qw/croak/;

sub SHOW_ADDRESS {
    my $self = shift;
    return $self->{+CHECK}->SHOW_ADDRESS;
}

sub lines {
    my $self = shift;

    return grep {defined $_} (
        $self->{+CHECK}->lines,
        $self->SUPER::lines(),
    );
}

sub operator {
    my $self = shift;
    return $self->{+CHECK}->not_operator;
}

sub post_build {
    my $self = shift;

    $self->SUPER::post_build();

    croak "'check' is a required attribute"
        unless $self->{+CHECK};
}

sub build {
    my $self = shift;
    my ($with, $alias) = @_;

    $self->{+CHECK} = $with
        if blessed($with)
        && $with->isa('Structure::Verify::Check');

    my $class = blessed($self);
    croak "'$class' does not know how to build with '$with'";
}

sub verify_meta {
    my $self = shift;
    return $self->{+CHECK}->verify_meta(@_);
}

sub verify_simple {
    my $self = shift;
    my $verify = $self->{+CHECK}->verify_simple(@_);
    return $verify unless defined $verify;
    return $verify ? 0 : 1;
}

sub verify_complex {
    my $self = shift;
    my %params = @_;

    my $delta = Structure::Verify::Delta->new();
    my $verify = $self->{+CHECK}->verify_complex(
        %params,
        delta => $delta,
    );
    return $verify unless defined $verify;
    return $verify ? 0 : 1;
}

sub subchecks {
    my $self = shift;

    my $class = blessed($self);
    my @subchecks = $self->{+CHECK}->subchecks(@_);

    $_->[1] = $class->new(check => $_->[1], lines => [$self->lines]) for @subchecks;

    return @subchecks;
}

sub cell {
    my $self = shift;
    $self->{+CHECK}->cell(@_);
}

1;
