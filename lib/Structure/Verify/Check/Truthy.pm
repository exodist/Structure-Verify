package Structure::Verify::Check::Truthy;
use strict;
use warnings;

use parent 'Structure::Verify::Check';
use Structure::Verify::HashBase qw/-true -false -defined -undefined -exists -non_existant/;

use Carp qw/croak/;

use Structure::Verify::Got;

my @ORDER = ( +TRUE, +FALSE, +DEFINED, +UNDEFINED, +EXISTS, +NON_EXISTANT );

sub operator { 'IN' }
sub negative_operator { 'NOT IN' }

sub from_string {
    my $class = shift;
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

    return $class->new(%specs);
}

sub init {
    my $self = shift;

    croak "At least one state must be specified"
        unless grep { $self->{$_} } @ORDER;
}

sub verify {
    my $self = shift;
    my ($got) = @_;

    unless ($got->exists) {
        return 1 if $self->{+NOT_EXISTING};
        return 0;
    }

    return 1 if $self->{+EXISTING};

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
