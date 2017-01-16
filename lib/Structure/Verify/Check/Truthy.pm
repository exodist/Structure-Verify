package Structure::Verify::Check::Truthy;
use strict;
use warnings;

use Structure::Verify::CheckMaker;
use Structure::Verify::HashBase qw/-true -false -defined -undefined -exists -non_existant/;

use Carp qw/croak/;

use Structure::Verify::Got;
use Term::Table::Cell;

my @ORDER = ( +TRUE, +FALSE, +DEFINED, +UNDEFINED, +EXISTS, +NON_EXISTANT );
my %ALLOW = map { $_ => $_ } @ORDER;

sub operator     { 'IN' }
sub not_operator { 'NOT IN' }

sub from_string {
    my $class = shift;
    return $class->new(_parse_string_args(@_));
}

sub post_build {
    my $self = shift;

    $self->SUPER::post_build();

    croak "At least one state must be specified"
        unless grep { $self->{$_} } @ORDER;
}

sub _parse_string_args {
    my ($str) = @_;
    my $orig = $str;

    my %specs;
    $specs{+DEFINED}      = 1 if $str =~ s/D//i;
    $specs{+EXISTS}       = 1 if $str =~ s/E//i;
    $specs{+FALSE}        = 1 if $str =~ s/F//i;
    $specs{+NON_EXISTANT} = 1 if $str =~ s/N//i;
    $specs{+TRUE}         = 1 if $str =~ s/T//i;
    $specs{+UNDEFINED}    = 1 if $str =~ s/U//i;

    $str =~ s/\s+//g;

    croak "The string '$orig' contains invalid or duplicate characters '$str'"
        if length($str);

    return %specs;
}

sub build {
    my $self = shift;
    my ($with, $alias) = @_;

    my $type = rtype($with);

    if (!$type) {
        $type = 'HASH';
        my %specs = _parse_string_args($with);
    }

    if ($type eq 'ARRAY') {
        $self->add_subcheck($_ => 1) for @$with;
        return;
    }
    elsif ($type eq 'HASH') {
        $self->add_subcheck($_ => $with->{$_}) for keys %$with;
        return;
    }

    return $self->SUPER::build(@_);
}

sub add_subcheck {
    my $self  = shift;
    my ($thing, $bool) = @_;

    croak "'$thing' is not a valid truthy state"
        unless $ALLOW{$thing};

    $bool = 1 unless defined $bool;

    $self->{$thing} = $bool;
}

sub verify_simple {
    my $self = shift;
    my ($got) = @_;

    unless ($got->exists) {
        return 1 if $self->{+NON_EXISTANT};
        return 0;
    }

    return 1 if $self->{+EXISTS};

    unless ($got->defined) {
        return 1 if $self->{+UNDEFINED};
        return 0;
    }

    return 1 if $self->{+DEFINED};

    my $value = $got->value;

    return 1 if $self->{+TRUE}  && $value;
    return 1 if $self->{+FALSE} && !$value;

    return 0;
}

sub cell {
    my $self = shift;

    return Term::Table::Cell->new(
        value        => join("\n" => grep { $self->{$_} } @ORDER),
        border_left  => '>',
        border_right => '<',
    );
}

1;
