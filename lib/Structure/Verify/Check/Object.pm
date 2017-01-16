package Structure::Verify::Check::Object;
use strict;
use warnings;

use Structure::Verify::CheckMaker;
use Structure::Verify::HashBase qw/-methods -type -subtypes/;

use Structure::Verify::Util::Ref qw/rtype/;
use Scalar::Util qw/blessed/;
use Carp qw/croak/;

use Structure::Verify::Check::SubType;
use Structure::Verify::Got;
use Term::Table::Cell;

sub not_operator { 'BLESSED' }
sub operator     { 'BLESSED' }

sub cell {
    my $self = shift;

    return Term::Table::Cell->new(
        border_left  => '>',
        border_right => '<',
        value        => $self->{+TYPE} ? $self->{+TYPE}->raw : 'Object',
    );
}

sub build {
    my $self = shift;
    my ($with, $alias) = @_;

    if (rtype($with) eq 'HASH') {
        $self->add_subcheck($_ => $with->{$_}) for keys %$with;
        return;
    }

    return $self->SUPER::build(@_);
}

sub pre_build {
    my $self = shift;

    $self->SUPER::pre_build();

    $self->{+METHODS}  ||= [];
    $self->{+SUBTYPES} ||= [];
}

sub verify_meta {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $got->exists;
    return 0 unless $got->defined;

    my $value = $got->value     or return 0;
    my $type  = blessed($value) or return 0;

    return 0 if $self->{+TYPE} && $self->{+TYPE}->raw ne $type;

    return 1;
}

sub subchecks {
    my $self = shift;
    my ($in_path, $got) = @_;

    my $value = $got->value;

    my @checks;

    push @checks => map {
        my $file  = $_->file;
        my $lines = $_->lines;
        my $type  = $_->raw;

        my $check = Structure::Verify::Check::SubType->new(
            'file'  => $file,
            'lines' => $lines,
            'type'  => $type,
        );

        [$in_path, $check, $got]
    } @{$self->{+SUBTYPES}};

    push @checks => map {
        my ($do, $check) = @{$_};

        my ($name, $run, $wrap);
        if (ref $do) {
            $run  = $do;
            $name = '...';
            $wrap = '';
        }
        else {
            $do =~ m/^(\@\%)?(.+)$/;
            ($wrap, $name, $run) = ($1, $2, $2);
        }

        $wrap ||= '';

        my $path = $in_path;
        $path .= "->$name()";
        $path = "[$path]" if $wrap eq '@';
        $path = "{$path}" if $wrap eq '%';

        my $got = Structure::Verify::Got->from_method($value, $run, $wrap, $self);

        [$path, $check, $got]
    } @{$self->{+METHODS}};

    return @checks;
}

sub add_subcheck {
    my $self = shift;
    my ($sub, $check) = @_;

    if ($sub eq '-blessed') {
        croak "type already set to '$self->{+TYPE}'"
            if $self->{+TYPE};

        $self->{+TYPE} = $check;

        return;
    }
    elsif ($sub eq '-isa') {
        push @{$self->{+SUBTYPES}} => $check;
        return;
    }

    push @{$self->{+METHODS}} => [$sub, $check];
}

1;
