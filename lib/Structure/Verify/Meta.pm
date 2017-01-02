package Structure::Verify::Meta;
use strict;
use warnings;

use Carp qw/croak carp/;

sub new;

use Structure::Verify::HashBase qw/-package -build_map -builds use_autoload/;

sub new {
    my $class = shift;
    my ($pkg) = @_;

    return $pkg->STRUCTURE_VERIFY
        if $pkg->can('STRUCTURE_VERIFY');

    my $self = bless(
        {
            BUILD_MAP() => {},
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

sub add_alias {
    my $self = shift;
    my ($alias, $mod) = @_;

    if (my $m = $self->{+BUILD_MAP}->{$alias}) {
        carp "check short name '$alias' was set to '$m' but is being reset to '$mod'"
            unless $mod eq $m;
    }

    $self->{+BUILD_MAP}->{$alias} = $mod;
}

sub find_build {
    my $self = shift;
    my ($alias) = @_;

    return $self->{+BUILD_MAP}->{$alias}
        if $self->{+BUILD_MAP}->{$alias};

    return unless $self->{+USE_AUTOLOAD};

    require Structure::Verify::Autoload;
    return Structure::Verify::Autoload->find($alias);
}

1;
