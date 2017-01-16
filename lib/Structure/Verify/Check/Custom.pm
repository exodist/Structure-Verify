package Structure::Verify::Check::Custom;
use strict;
use warnings;

use Structure::Verify::CheckMaker;
use Structure::Verify::HashBase qw/-code -name -operator/;

use Structure::Verify::Util::Ref qw/rtype/;
use Sub::Info qw/sub_info/;
use Carp qw/croak/;

sub pre_build {
    my $self = shift;

    $self->SUPER::pre_build();

    $self->{+OPERATOR} ||= '->(...)';
}

sub post_build {
    my $self = shift;

    $self->SUPER::post_build();

    croak "The 'code' attribute is required"
        unless $self->{+CODE};

    croak "The 'code' attribute must be a coderef"
        unless rtype($self->{+CODE}) eq 'CODE';
}

sub verify_type { undef }

sub verify {
    my $self = shift;
    my ($got) = @_;
    return $self->{+CODE}->($got) ? 1 : 0;
}

sub build {
    my $self = shift;
    my ($with, $alias) = @_;

    my $type = rtype($with);

    if ($type eq 'CODE') {
        $self->{+CODE} = $with;
        return;
    }
    elsif ($type eq 'HASH') {
        $self->{+CODE} = $with->{code} or die "'code' is required";

        $self->{+NAME}     = $with->{name}     if defined $with->{name};
        $self->{+OPERATOR} = $with->{operator} if defined $with->{operator};
        return;
    }

    return $self->SUPER::build(@_);
}

sub cell {
    my $self = shift;

    my $name = $self->{+NAME};
    unless ($name) {
        my $info = sub_info($self->{+CODE});

        if ($info->{name} =~ m/__ANON__/) {
            my $file =~ s{^.*/}{.../}g;
            $name = "CODE at $file lines $info->{start_line} -> $info->{end_line}";
        }
        else {
            $name = $info->{name};
        }
    }

    return Term::Table::Cell->new(
        value        => $name,
        border_left  => '>',
        border_right => '<',
    );
}

1;
