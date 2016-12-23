package Structure::Verify::Meta;
use strict;
use warnings;

use Carp qw/croak/;

sub new;

use Structure::Verify::HashBase qw/-package -build_map/;

sub new {
    my $class = shift;
    my ($pkg) = @_;

    return $pkg->STRUCTURE_VERIFY
        if $pkg->can('STRUCTURE_VERIFY');

    my $self = bless {BUILD_MAP() => {}, PACKAGE() => $pkg}, $class;

    {
        no strict 'refs';
        *{"$pkg\::STRUCTURE_VERIFY"} = sub { $self };
    }

    return $self;
}

sub _load {
    my $self = shift;

    my @modules;
    for my $check (@_) {
        my $loaded = 0;

        for my $base ('Check/Value', 'Check/Container', 'Check') {
            my $file = "Structure/Verify/$base/$check.pm";

            my $error;
            {
                local ($@, $!, $?);
                $loaded = $file if eval { require $file; 1 };
                $error = $@;
            }

            last if $loaded;
            next if $error =~ m/Can't locate \Q$file\E in \@INC/;
            die $error;
        }

        my $mod = $loaded or croak "Could not find check $check";

        $mod =~ s{/}{::}g;
        $mod =~ s{\.pm$}{}g;

        push @modules => $mod;
    }

    return @modules;
}

sub load {
    my $self = shift;

    my @modules = $self->_load(@_);

    for my $mod (@modules) {
        my $alias = $mod->BUILD_ALIAS;
        $self->{+BUILD_MAP}->{$alias} = $mod;
    }

    return;
}

sub load_as {
    my $self = shift;

    my (@checks, @aliases);
    while (@_) {
        push @checks  => shift;
        push @aliases => shift;
    }

    my @modules = $self->_load(@checks);

    while (@modules) {
        my $module = shift @modules;
        my $alias  = shift @aliases;

        $self->{+BUILD_MAP}->{$alias} = $module;
    }

    return;
}

1;
