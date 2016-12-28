package Structure::Verify::Check::Bag;
use strict;
use warnings;

use parent 'Structure::Verify::Check';

use Structure::Verify::HashBase qw/-components bounded/;

use Structure::Verify::Util::Ref qw/rtype/;
use Structure::Verify qw/run_checks/;
use Scalar::Util qw/blessed/;
use Carp qw/croak/;

use Structure::Verify::Check::Boundary;
use Structure::Verify::Got;
use Term::Table::Cell;

sub BUILD_ALIAS { 'bag' }

sub operator { 'IS' }

sub init {
    my $self = shift;

    $self->SUPER::init();

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
    my $check = pop;
    my $count = @_ ? shift : 1;

    croak "Count $count is invalid, must be 0 or greater"
        if $count < 0;

    push @{$self->{+COMPONENTS}} => [$count, $check];
}

sub build {
    my $self = shift;
    my ($with, $alias) = @_;

    if (rtype($with) eq 'ARRAY') {
        push @{$self->{+COMPONENTS}} => map {[1, $_]} @$with;
        return;
    }

    return $self->SUPER::build(@_);
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
        my $want_count = $components->[$c]->[0];
        my $check      = $components->[$c]->[1];
        $check = $convert->($check) if $convert;

        for (my $v = 0; $v < @$value; $v++) {
            my ($ok) = run_checks($value->[$v], $check, convert => $convert, path => "$path\[$c]");

            next unless $ok;
            push @{$c_ok->{$c}} => $value->[$v];
            $v_ok->{$v}++;
        }

        my $count = $c_ok->{$c} ? @{$c_ok->{$c}} : 0;

        next if $count == $want_count;
        $bad++;

        for (my $v = 0; $v < $count || $v < $want_count; $v++) {
            $delta->add(
                "$path\<$c>",
                $check,
                Structure::Verify::Got->from_array_idx($c_ok->{$c}, $v),
                notes => "Match " . ($v + 1) . " of $want_count",
                ($v > $count || $v > $want_count) ? ('*' => '*') : (),
            );
        }

        $delta->add_space if $count > 1 || $want_count > 1;
    }

    return !$bad unless $self->{+BOUNDED};

    for (my $v = 0; $v < @$value; $v++) {
        next if $v_ok->{$v};

        $bad++;
        $delta->add(
            "$path\[$v]",
            Structure::Verify::Check::Boundary->new(lines => [$self->lines]),
            Structure::Verify::Got->from_array_idx($value, $v)
        );
    }

    return !$bad;
}

sub _render_trace {
    my $check = shift;

    my $file  = $check->file;
    my @lines = $check->lines;

    return '' unless $file || @lines;

    my $out = "";
    $out .= "at $file"                     if $file;
    $out .= " "                            if @lines;
    $out .= "line $lines[0]"               if @lines == 1;
    $out .= "lines $lines[0] -> $lines[1]" if @lines == 2;
    $out .= "lines " . join(', ', @lines)  if @lines > 2;

    return "($out)\n  ";
}

1;

__END__
            my $b_trace = _render_trace($self);
            my $c_trace = _render_trace($check);

            warn "Check <${c}${alias}> ${c_trace}in bag ${b_trace}matches too many items in the array:\n$values\n";

