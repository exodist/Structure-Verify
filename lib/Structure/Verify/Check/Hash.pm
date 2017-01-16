package Structure::Verify::Check::Hash;
use strict;
use warnings;

use Structure::Verify::CheckMaker;
use Structure::Verify::HashBase qw/-components bounded/;

use Carp qw/croak/;
use Structure::Verify::Util::Ref qw/rtype/;

use Structure::Verify::Got;
use Structure::Verify::Check::Boundary;
use Term::Table::Cell;

sub operator     { 'IS' }
sub not_operator { 'IS NOT' }

sub cell {
    return Term::Table::Cell->new(
        value        => 'HashRef',
        border_left  => '>',
        border_right => '<',
    );
}

sub build {
    my $self = shift;
    my ($with, $alias) = @_;

    if (rtype($with)  eq 'HASH') {
        $self->add_subcheck($_ => $with->{$_}) for keys %$with;
        return;
    }

    return $self->SUPER::build(@_);
}

sub pre_build {
    my $self = shift;

    $self->SUPER::pre_build();

    $self->{+COMPONENTS} ||= [];
}

sub verify { undef }

sub verify_type {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $got->exists;
    return 0 unless $got->defined;

    my $value = $got->value or return 0;
    return 0 unless rtype($value) eq 'HASH';
    return 1;
}

sub subchecks {
    my $self = shift;
    my ($path, $got) = @_;

    my $value = $got->value;

    my (@subchecks, %seen);
    for my $set (@{$self->{+COMPONENTS}}) {
        my ($key, $check) = @$set;

        $seen{$key} = 1;

        my $got = Structure::Verify::Got->from_hash_key($value, $key);

        push @subchecks => ["$path\{$key}", $check, $got];
    }

    if ($self->{+BOUNDED}) {
        for my $key (sort keys %$value) {
            next if $seen{$key};

            my $got = Structure::Verify::Got->from_hash_key($value, $key);

            push @subchecks => [
                "$path\{$key}",
                Structure::Verify::Check::Boundary->new(lines => [$self->lines]),
                $got,
            ];
        }
    }

    return @subchecks;
}

sub add_subcheck {
    my $self = shift;
    my ($key, $check) = @_;

    croak "add_subcheck requires exactly 2 arguments when used with a hash"
        unless @_ == 2;

    push @{$self->{+COMPONENTS}} => [$key, $check];
}

1;
