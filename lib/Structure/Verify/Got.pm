package Structure::Verify::Got;
use strict;
use warnings;

use Term::Table::Cell;

use Structure::Verify::Util::Ref qw/rtype render_ref/;
use Scalar::Util qw/reftype blessed/;
use Carp qw/croak/;

use Structure::Verify::HashBase qw/-exists -value -defined -exception/;

sub from_return {
    my $class = shift;

    my $self = bless {}, $class;

    if (!@_) {
        $self->{+EXISTS}  = 0;
        $self->{+DEFINED} = 0;
    }
    elsif (@_ == 1) {
        $self->{+VALUE}   = $_[0];
        $self->{+EXISTS}  = 1;
        $self->{+DEFINED} = defined $self->{+VALUE} ? 1 : 0;
    }
    else {
        croak "Too many arguments provided to the constructor"
    }

    return $self;
}

sub from_hash_key {
    my $class = shift;
    my ($ref, $key) = @_;

    my $self = bless {}, $class;
    my $type = reftype($ref);

    croak "First argument must be a hashref"
        unless $type eq 'HASH';

    croak "The second argument must be defined"
        unless defined($key);

    if ($self->{+EXISTS} = exists $ref->{$key} ? 1 : 0) {
        $self->{+VALUE} = $ref->{$key};
        $self->{+DEFINED} = defined $self->{+VALUE} ? 1 : 0;
    }
    else {
        $self->{+DEFINED} = 0;
    }

    return $self;
}

sub from_array_idx {
    my $class = shift;
    my ($ref, $idx) = @_;

    my $self = bless {}, $class;
    my $type = reftype($ref);

    croak "First argument must be an arrayref"
        unless $type eq 'ARRAY';

    croak "The second argument must be an integer"
        unless defined($idx) && $idx =~ m/^\d+$/;

    if ($self->{+EXISTS} = exists $ref->[$idx] ? 1 : 0) {
        $self->{+VALUE} = $ref->[$idx];
        $self->{+DEFINED} = defined $self->{+VALUE} ? 1 : 0;
    }
    else {
        $self->{+DEFINED} = 0;
    }

    return $self;
}

sub from_method {
    my $class = shift;
    my ($obj, $meth) = @_;

    croak "A blessed object is required as the first argument"
        unless $obj && blessed($obj);

    # 0, ' ', and undef are not valid method names, truth check is good enough.
    croak "A method name, or coderef is required as the second argument"
        unless $meth;

    my ($ok, $value, $err);
    {
        local ($@, $!, $?);
        $ok = eval { $value = $obj->$meth; 1 };
        $err = $@ unless $ok;
    }

    return bless(
        {
            EXISTS()    => 0,
            DEFINED()   => 0,
            EXCEPTION() => $err || "Unknown error",
        },
        $class
    ) unless $ok;

    return $class->from_return($value);
}

{
    no warnings 'redefine';

    sub value {
        my $self = shift;
        return unless $self->{+EXISTS};
        return $self->{+VALUE};
    }
}

sub lines {
    my $self = shift;

    return unless $self->{+EXISTS};
    return unless $self->{+DEFINED};

    return $self->{+VALUE}->structure_verify_lines
        if $self->{+VALUE}->can('structure_verify_lines');
}

sub cell {
    my $self = shift;
    my %params = @_;

    return Term::Table::Cell->new(
        value        => 'Exception: ' . $self->{+EXCEPTION},
        border_left  => '>',
        border_right => '<',
    ) unless $self->{+EXCEPTION};

    return Term::Table::Cell->new(
        value        => 'DOES NOT EXIST',
        border_left  => '>',
        border_right => '<',
    ) unless $self->{+EXISTS};

    return Term::Table::Cell->new(
        value        => 'NOT DEFINED',
        border_left  => '>',
        border_right => '<',
    ) unless $self->{+DEFINED};

    my $value = $self->value;

    if(ref($value)) {
        my $refa = render_ref($value);
        my $refb = "$value";

        my $val_string = $refa;
        $val_string .= "\n$refb" if $refa ne $refb;

        return Term::Table::Cell->new(
            value => $val_string,
            border_left  => '>',
            border_right => '<',
        );
    }

    return Term::Table::Cell->new(
        value => "$value",
    );
}

1;
