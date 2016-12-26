package Structure::Verify::Check::Container::Object;
use strict;
use warnings;

use parent 'Structure::Verify::Check::Container';

use Structure::Verify::HashBase qw/-methods/;

use Structure::Verify::Util::Ref qw/rtype/;
use Scalar::Util qw/blessed/;

use Structure::Verify::Got;
use Term::Table::Cell;

sub BUILD_ALIAS { 'object' }

sub operator { 'IS' }

sub cell {
    return Term::Table::Cell->new(
        value        => 'Object',
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

sub init {
    my $self = shift;

    $self->SUPER::init();

    $self->{+METHODS} ||= [];
}

sub verify {
    my $self = shift;
    my ($got) = @_;

    return 0 unless $got->exists;
    return 0 unless $got->defined;

    my $value = $got->value or return 0;
    return 0 unless blessed($value);
    return 1;
}

sub subchecks {
    my $self = shift;
    my ($path, $got) = @_;

    my $value = $got->value;

    return map {
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

        $path = "$path\->$name()";
        $path = "[$path]" if $wrap eq '@';
        $path = "{$path}" if $wrap eq '%';

        my $got = Structure::Verify::Got->from_method($value, $run, $wrap, $self);

        [$path, $check, $got]
    } @{$self->{+METHODS}};
}

sub add_subcheck {
    my $self = shift;
    my ($sub, $check) = @_;

    push @{$self->{+METHODS}} => [$sub, $check];
}

1;

