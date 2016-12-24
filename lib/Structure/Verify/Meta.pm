package Structure::Verify::Meta;
use strict;
use warnings;

use Carp qw/croak carp/;

sub new;

use Structure::Verify::HashBase qw/-package -build_map -builds/;

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

    my @out;
    for my $mod (@modules) {
        my @aliases = $mod->BUILD_ALIAS;

        for my $alias (@aliases) {
            if (my $m = $self->{+BUILD_MAP}->{$alias}) {
                carp "check short name '$alias' was set to '$m' but is being reset to '$mod'"
                    unless $mod eq $m;
            }

            $self->{+BUILD_MAP}->{$alias} = $mod;
            push @out => ($alias, $mod);
        }
    }

    return @out;
}

sub load_as {
    my $self = shift;

    my (@checks, @aliases);
    while (@_) {
        push @checks  => shift;
        push @aliases => shift;
    }

    my @modules = $self->_load(@checks);

    my @out;
    while (@modules) {
        my $module = shift @modules;
        my $alias  = shift @aliases;

        if (my $mod = $self->{+BUILD_MAP}->{$alias}) {
            carp "check short name '$alias' was set to '$mod' but is being reset to '$module'"
                unless $mod eq $module;
        }

        $self->{+BUILD_MAP}->{$alias} = $module;
        push @out => ($alias, $module);
    }

    return @out;
}

1;
