package Structure::Verify::Check::Container::Hash;
use strict;
use warnings;

use parent 'Structure::Verify::Check::Container';

use Structure::Verify::HashBase qw/-components bounded/;

use Structure::Verify::Util::Ref qw/rtype/;

use Structure::Verify::Got;
use Structure::Verify::Check::Boundary;
use Term::Table::Cell;

sub operator { 'IS' }

sub cell {
    return Term::Table::Cell->new(
        value        => 'HashRef',
        border_left  => '>',
        border_right => '<',
    );
}

sub init {
    my $self = shift;

    $self->{+COMPONENTS} ||= [];
}

sub verify {
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

        push @subchecks => ["$path\->{$key}", $check, $got];
    }

    if ($self->{+BOUNDED}) {
        for my $key (keys %$value) {
            next if $seen{$key};

            my $got = Structure::Verify::Got->from_hash_key($value, $key);

            push @subchecks => [
                "$path\->{$key}",
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

    push @{$self->{+COMPONENTS}} => [$key, $check];
}

1;