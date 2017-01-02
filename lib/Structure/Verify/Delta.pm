package Structure::Verify::Delta;
use strict;
use warnings;

use Structure::Verify::HashBase qw/-rows/;

use Term::Table;
use Term::Table::Cell;
use Term::Table::Spacer;

use Structure::Verify::Util::Ref qw/render_ref rtype ref_cell/;
use Scalar::Util qw/blessed/;

sub init {
    my $self = shift;

    $self->{+ROWS} ||= [];
}

sub add {
    my $self = shift;
    my ($path, $check, $got, %params) = @_;
    push @{$self->{+ROWS}} => [$path, $check, $got, %params];
}

my $SPACE = [];

sub add_space {
    my $self = shift;
    push @{$self->{+ROWS}} => $SPACE;
}

sub term_table {
    my $self   = shift;
    my %params = @_;

    my $colors     = $params{colors}     || {};
    my $table_args = $params{table_args} || {};

    my @rows = map {
        my ($path, $check, $got, %params) = @{$_};

        my (%seen1, %seen2);
        my $got_lines   = defined($got)   ? join ', ' => grep { !$seen1{$_}++ } $got->lines   : '';
        my $check_lines = defined($check) ? join ', ' => grep { !$seen2{$_}++ } $check->lines : '';
        my $operator = defined($check) ? $check->operator : '';
        my $star  = $params{'*'}     || '';
        my $notes = $params{'notes'} || '';

        $_ == $SPACE ? [Term::Table::Spacer->new] : [
            $self->cell(path        => $path,        $check, $colors->{path}),
            $self->cell(got_lines   => $got_lines,   $check, $colors->{got_lines}),
            $self->cell(got         => $got,         $check, $colors->{got}),
            $self->cell(operator    => $operator,    $check, $colors->{operator}),
            $self->cell(check       => $check,       $check, $colors->{check}),
            $self->cell(star        => $star,        $check, $colors->{star}),
            $self->cell(check_lines => $check_lines, $check, $colors->{check_lines}),
            $self->cell(notes       => $notes,       $check, $colors->{notes}),
        ];
    } @{$self->{+ROWS}};

    pop @rows if $self->{+ROWS}->[-1] == $SPACE;

    return Term::Table->new(
        collapse    => 1,
        sanitize    => 1,
        mark_tail   => 1,
        show_header => 1,

        %$table_args,

        header      => [qw/PATH LINES GOT OP CHECK * LINES NOTES/],
        no_collapse => [qw/GOT CHECK/],
        rows        => \@rows,
    );
}

sub cell {
    my $self = shift;
    my ($name, $input, $check, $colors) = @_;

    return $input unless defined $input;

    my $length = length($input);
    my $type   = rtype($input);

    my ($can, $isa, $got);
    if (blessed $input) {
        $can = $input->can('cell') || 0;
        $isa = $input->isa('Term::Table::Cell') || $input->isa('Term::Table::CellStack') || 0;
        $got = $input->isa('Structure::Verify::Got');
    }

    # Short-Circuit
    return $input unless $length || $type || $can || $isa;

    my $show_address = $check ? $check->SHOW_ADDRESS : 0;

    my $cell;
    if    ($isa)  { $cell = $input }
    elsif ($can)  { $cell = $input->cell(show_address => $show_address) }
    elsif ($type) { $cell = ref_cell($input, !$show_address) }
    else          { $cell = Term::Table::Cell->new(value => $input) }

    return $cell unless $colors;

    for my $c ($cell->isa('Term::Table::CellStack') ? @{$cell->cells} : $cell) {
        $c->set_border_color($colors->{border}) if exists $colors->{border};
        $c->set_value_color($colors->{value})   if exists $colors->{value};
        $c->set_reset_color($colors->{reset})   if exists $colors->{reset};
    }

    return $cell;
}

1;

