package Structure::Verify::Got;
use strict;
use warnings;

use Term::Table::Cell;
use Term::Table::CellStack;

use Structure::Verify::Util::Ref qw/render_ref rtype ref_cell/;
use Scalar::Util qw/blessed/;
use Carp qw/croak/;

use Structure::Verify::HashBase qw/-exists -value -defined -exception -meta/;

sub from_verify_input {
    my $class = shift;
    my ($in) = @_;

    return $in if blessed($in) && $in->isa(__PACKAGE__);

    return $class->from_return(@_);
}

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
        croak "Too many arguments provided to the constructor";
    }

    return $self;
}

sub from_hash_key {
    my $class = shift;
    my ($ref, $key) = @_;

    my $self = bless {}, $class;
    my $type = rtype($ref);

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
    my $type = rtype($ref);

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
    my ($obj, $meth, $wrap, $check) = @_;
    $wrap ||= "";

    croak "A blessed object is required as the first argument"
        unless $obj && blessed($obj);

    # 0, ' ', and undef are not valid method names, truth check is good enough.
    croak "A method name, or coderef is required as the second argument"
        unless $meth;

    my ($ok, $err, @out);
    {
        local ($@, $!, $?);
        if ($wrap) {
            # List context due to wrapping
            $ok = eval { @out = $obj->$meth; 1 };
        }
        else {
            # Scalar context, in case of wantarray
            $ok = eval { $out[0] = $obj->$meth; 1 };
        }
        $err = $@ unless $ok;
    }

    return bless({
            EXISTS()    => 0,
            DEFINED()   => 0,
            EXCEPTION() => $err || "Unknown error",
        },
        $class
    ) unless $ok;

    return $class->from_return(\@out)
        if $wrap eq '@';

    if ($wrap eq '%') {
        my $out;

        # Using 'while' to essentially make an if block that we can break out
        # of.
        my ($line, $file);
        while ($check) {
            my @lines = $check->lines or last;
            $line = $lines[-1];
            $file = $check->file;
            last;
        }

        $line ||= 0;
        $file ||= '';
        $file .= ' (eval in ' . __FILE__ . ' line ' . __LINE__ . ')';

        {
            local ($@, $!, $?);
            $ok  = eval qq[#line $line "$file"\n\$out = {\@out}; 1];
            $err = $@;
        }

        die $err unless $ok;

        return $class->from_return($out);
    }

    return $class->from_return(@out);
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
        if blessed($self->{+VALUE})
        && $self->{+VALUE}->can('structure_verify_lines');

    return;
}

sub cell {
    my $self   = shift;
    my %params = @_;

    return Term::Table::Cell->new(
        value        => 'Exception: ' . $self->{+EXCEPTION},
        border_left  => '>',
        border_right => '<',
    ) if $self->{+EXCEPTION};

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

    return Term::Table::Cell->new(
        value => "$value",
        $self->{+META}
        ? (
            border_left  => '>',
            border_right => '<',
            )
        : (),
    ) unless ref($value);

    return ref_cell($value, $params{show_address});
}

1;
