package Structure::Verify::Check::Container::Array;
use strict;
use warnings;

use parent 'Structure::Verify::Check::Container';

use Structure::Verify::HashBase qw/-components -idx bounded/;

use Structure::Verify::Util::Ref qw/rtype/;
use List::Util qw/max/;

use Structure::Verify::Check::Boundary;
use Structure::Verify::Got;
use Term::Table::Cell;

sub BUILD_ALIAS { 'array' }

sub operator { 'IS' }

sub build {
    my $self = shift;
    my ($with, $alias) = @_;

    my $type = rtype($with);

    if ($type eq 'ARRAY') {
        $self->add_subcheck($_) for @$with;
        return;
    }
    elsif ($type eq 'HASH') {
        $self->add_subcheck($_ => $with->{$_}) for keys %$with;
        return;
    }

    return $self->SUPER::build(@_);
}

sub cell {
    return Term::Table::Cell->new(
        value        => 'ArrayRef',
        border_left  => '>',
        border_right => '<',
    );
}

sub init {
    my $self = shift;

    $self->SUPER::init();

    $self->{+IDX} ||= 0;
    $self->{+COMPONENTS} ||= [];
}

sub verify {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $got->exists;
    return 0 unless $got->defined;

    my $value = $got->value or return 0;
    return 0 unless rtype($value) eq 'ARRAY';
    return 1;
}

sub subchecks {
    my $self = shift;
    my ($path, $got) = @_;

    my $value = $got->value;

    my (@subchecks, @seen);
    for my $set (@{$self->{+COMPONENTS}}) {
        my ($idx, $check) = @$set;
        push @seen => $idx;

        my $got = Structure::Verify::Got->from_array_idx($value, $idx);

        push @subchecks => ["$path\->[$idx]", $check, $got];
    }

    if ($self->{+BOUNDED}) {
        my $idx = @seen ? max(@seen) + 1 : 0;
        my $got = Structure::Verify::Got->from_array_idx($value, $idx);

        push @subchecks => [
            "$path\->[$idx]",
            Structure::Verify::Check::Boundary->new(lines => [$self->lines]),
            $got,
        ];
    }

    return @subchecks;
}

sub add_subcheck {
    my $self  = shift;
    my $check = pop;
    my $idx   = @_ ? shift : $self->{+IDX}++;

    push @{$self->{+COMPONENTS}} => [$idx, $check];
}

1;
