package Structure::Verify::Meta;
use strict;
use warnings;

use Carp qw/croak carp/;

sub new;

use Structure::Verify::HashBase qw/-package -builds/;

sub new {
    my $class = shift;
    my ($pkg) = @_;

    return $pkg->STRUCTURE_VERIFY
        if $pkg->can('STRUCTURE_VERIFY');

    my $self = bless(
        {
            PACKAGE() => $pkg,
            BUILDS() => [],
        },
        $class
    );

    {
        no strict 'refs';
        *{"$pkg\::STRUCTURE_VERIFY"} = sub { $self };
    }

    return $self;
}

sub current_build {
    my $self = shift;
    my $builds = $self->{+BUILDS};

    return unless @$builds;
    return $builds->[-1];
}

1;
