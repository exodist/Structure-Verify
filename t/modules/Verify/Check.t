use strict;
use warnings;
BEGIN { require 't/is.pm'; is->import }

my $CLASS = 'Structure::Verify::Check';
use ok 'Structure::Verify::Check';

ok($CLASS->can($_), "The '$_' method is defined") for qw/file via_build lines/;

ok(!$CLASS->SHOW_ADDRESS, "Do not show memory addresses by default");

like(
    exception { $CLASS->operator },
    qr/$CLASS does not implement operator\(\)/,
    "No operator"
);

like(
    exception { $CLASS->verify },
    qr/$CLASS does not implement verify\(\)/,
    "No way to verify"
);

my $one = $CLASS->new(lines => [1,2,3]);
is([$one->lines], [1,2,3], "got lines");

my $two = $one->clone;
is_deeply($one, $two, "Clone");
ok($one != $two, "Not the same ref");


done_testing;

__END__

sub build {
    my $self = shift;
    my ($with, $alias) = @_;

    my $type = rtype($with);

    return $with->($self, $alias)
        if $type eq 'CODE';

    return $self->{$self->VALUE} = $with
        if $self->can('value') && (!$type || $type eq 'REGEXP');

    my $class = blessed($self);
    croak "'$class' does not know how to build with '$with'"
}

sub cell {
    my $self = shift;

    return Term::Table::Cell->new(
        value        => 'CHECK',
        border_left  => '>',
        border_right => '<',
    ) unless $self->can('value');

    my $value = $self->value;

    return Term::Table::Cell->new(
        value        => 'NOT DEFINED',
        border_left  => '>',
        border_right => '<',
    ) unless defined $value;

    return Term::Table::Cell->new(value => "$value")
        unless ref $value;

    return ref_cell($value, $self->SHOW_ADDRESS);
}


1;
