package Structure::Verify::Check::Bag;
use strict;
use warnings;

use parent 'Structure::Verify::Check';

use Structure::Verify::HashBase qw/-components bounded/;

use Structure::Verify::Util::Ref qw/rtype/;
use Structure::Verify qw/run_checks/;

use Structure::Verify::Check::Boundary;
use Structure::Verify::Got;
use Term::Table::Cell;

sub operator { 'IS' }

sub init {
    my $self = shift;

    $self->{+COMPONENTS} ||= [];
}

sub cell {
    return Term::Table::Cell->new(
        value        => 'ArrayRef',
        border_left  => '>',
        border_right => '<',
    );
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

sub add_subcheck {
    my $self = shift;
    my ($check) = @_;
    push @{$self->{+COMPONENTS}} => $check;
}

sub complex_check {
    my $self   = shift;
    my %params = @_;

    my $g       = $params{got};
    my $path    = $params{path};
    my $delta   = $params{delta};
    my $convert = $params{convert};

    my $components = $self->{+COMPONENTS};
    my $value      = $g->value;

    my $bad  = 0;
    my $c_ok = {};
    my $v_ok = {};

    for (my $c = 0; $c < @$components; $c++) {
        my $check = $components->[$c];
        $check = $convert->($check) if $convert;

        for (my $v; $v < @$value; $v++) {
            my $val = Structure::Verify::Got->from_return($value->[$v]);
            my ($ok) = run_check($val, $check, convert => $convert, path => "$path->[$c]");
            $c_ok->{$c} = 1 if $ok;
            $v_ok->{$v} = 1 if $ok;

            last if $c_ok->{$c} && ($v_ok->{$v} || !$self->{+BOUNDED});
        }

        next if $c_ok->{$c};

        $bad++;
        $delta->add(
            "$path\->[<$c>]",
            $check,
            Structure::Verify::Got->from_return()
        );
    }

    return !$bad unless $self->{+BOUNDED};

    for (my $v; $v < @$value; $v++) {
        next if $v_ok->{$v};

        $bad++;
        $delta->add(
            "$path\->[$v]",
            Structure::Verify::Check::Boundary->new(lines => [$self->lines]),
            Structure::Verify::Got->from_array_idx($value, $v)
        );
    }
}

1;
