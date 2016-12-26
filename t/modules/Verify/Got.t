use Test2::Tools::Tiny;
use strict;
use warnings;

use Structure::Verify::Got;
use Structure::Verify qw/build load_check/;
load_check 'String';

my $CLASS = 'Structure::Verify::Got';

ok($CLASS->can($_), "accessor $_\() present") for qw{exists value defined exception};

my $one;

tests from_value => sub {
    $one = $CLASS->from_return();
    is($one->exists,  0, "it does not exist");
    is($one->defined, 0, "it is not defined");
    is_deeply([$one->value], [], "value return nothing");

    $one = $CLASS->from_return(undef);
    is($one->exists,  1, "it does exist");
    is($one->defined, 0, "it is not defined");
    is_deeply([$one->value], [undef], "value returns undef");

    $one = $CLASS->from_return(0);
    is($one->exists,  1, "it does exist");
    is($one->defined, 1, "it is defined");
    is_deeply([$one->value], [0], "value returns 0");

    $one = $CLASS->from_return('abc');
    is($one->exists,  1, "it does exist");
    is($one->defined, 1, "it is defined");
    is_deeply([$one->value], ['abc'], "value returns 'abc'");

    like(
        exception { $CLASS->from_return(0, 1) },
        qr/Too many arguments provided to the constructor/,
        "Only 0 or 1 args"
    );
};

tests from_hash_key => sub {
    $one = $CLASS->from_hash_key({}, 'a');
    is($one->exists,  0, "it does not exist");
    is($one->defined, 0, "it is not defined");
    is_deeply([$one->value], [], "value return nothing");

    $one = $CLASS->from_hash_key({a => undef}, 'a');
    is($one->exists,  1, "it does exist");
    is($one->defined, 0, "it is not defined");
    is_deeply([$one->value], [undef], "value returns undef");

    $one = $CLASS->from_hash_key({a => 0}, 'a');
    is($one->exists,  1, "it does exist");
    is($one->defined, 1, "it is defined");
    is_deeply([$one->value], [0], "value returns 0");

    $one = $CLASS->from_hash_key({a => 'abc'}, 'a');
    is($one->exists,  1, "it does exist");
    is($one->defined, 1, "it is defined");
    is_deeply([$one->value], ['abc'], "value returns 'abc'");

    like(
        exception { $CLASS->from_hash_key(0) },
        qr/First argument must be a hashref/,
        "First arg must be a hash"
    );

    like(
        exception { $CLASS->from_hash_key({}) },
        qr/The second argument must be defined/,
        "Second arg must be defined"
    );
};

tests from_array_idx => sub {
    $one = $CLASS->from_array_idx([], 0);
    is($one->exists,  0, "it does not exist");
    is($one->defined, 0, "it is not defined");
    is_deeply([$one->value], [], "value return nothing");

    $one = $CLASS->from_array_idx([undef], 0);
    is($one->exists,  1, "it does exist");
    is($one->defined, 0, "it is not defined");
    is_deeply([$one->value], [undef], "value returns undef");

    $one = $CLASS->from_array_idx([0], 0);
    is($one->exists,  1, "it does exist");
    is($one->defined, 1, "it is defined");
    is_deeply([$one->value], [0], "value returns 0");

    $one = $CLASS->from_array_idx(['abc'], 0);
    is($one->exists,  1, "it does exist");
    is($one->defined, 1, "it is defined");
    is_deeply([$one->value], ['abc'], "value returns 'abc'");

    like(
        exception { $CLASS->from_array_idx(0) },
        qr/First argument must be an arrayref/,
        "First arg must be an array"
    );

    like(
        exception { $CLASS->from_array_idx([], 'z') },
        qr/The second argument must be an integer/,
        "Second arg must be an integer"
    );
};

tests from_method => sub {
    {
        package TestObj;
        use Structure::Verify::HashBase qw/foo bar baz/;

        sub all_list {
            my $self = shift;

            return (
                foo => $self->{+FOO},
                bar => $self->{+BAR},
                baz => $self->{+BAZ},
            );
        }

        sub all_array {
            my $self = shift;
            my @array = $self->all_list;
            return @array;
        }

        sub want { wantarray ? (1, 2, 3) : 'abc' }

        sub nope { return }
    }

    my $obj = TestObj->new(
        foo => 'foo',
        bar => undef,
        baz => 0
    );

    tests scalar_context => sub {
        $one = $CLASS->from_method($obj, 'all_list');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply([$one->value], [0], "Normal behavior for list return in scalar context, got last value");

        $one = $CLASS->from_method($obj, 'all_array');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply([$one->value], [6], "Normal behavior for array return in scalar context, got count");

        $one = $CLASS->from_method($obj, 'want');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply([$one->value], ['abc'], "Got scalar value");

        $one = $CLASS->from_method($obj, 'nope');
        is($one->exists,  1, "it does exist");
        is($one->defined, 0, "it is not defined");
        is_deeply([$one->value], [undef], "Got scalar value of an empty list (undef)");

        $one = $CLASS->from_method($obj, 'foo');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply([$one->value], ['foo'], "Got simple scalar return");
    };

    tests array_wrap => sub {
        $one = $CLASS->from_method($obj, 'all_list', '@');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply($one->value, [foo => 'foo', bar => undef, baz => 0], "Wrapped in an array");

        $one = $CLASS->from_method($obj, 'all_array', '@');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply($one->value, [foo => 'foo', bar => undef, baz => 0], "Wrapped in an array");

        $one = $CLASS->from_method($obj, 'want', '@');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply($one->value, [1, 2, 3], "Got list");

        $one = $CLASS->from_method($obj, 'nope', '@');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is not defined");
        is_deeply($one->value, [], "Got empty arrayref");

        $one = $CLASS->from_method($obj, 'foo', '@');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply($one->value, ['foo'], "Scalar was wrapped in an array");
    };

    tests hash_wrap => sub {
        $one = $CLASS->from_method($obj, 'all_list', '%');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply($one->value, {foo => 'foo', bar => undef, baz => 0}, "Wrapped in a hash");

        $one = $CLASS->from_method($obj, 'all_array', '%');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply($one->value, {foo => 'foo', bar => undef, baz => 0}, "Wrapped in a hash");

        my $line;
        my $file = __FILE__;

        my $warnings = warnings {
            $line = __LINE__ + 1;
            $one = $CLASS->from_method($obj, 'want', '%', build string => '123');
        };

        like(
            $warnings->[0],
            qr/Odd number of elements in anonymous hash at \Q$file\E \(eval in[^\)]+\) line $line/,
            "Warning reported to the check"
        );

        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply($one->value, {1 => 2, 3 => undef}, "Got list");

        $one = $CLASS->from_method($obj, 'nope', '%');
        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is not defined");
        is_deeply($one->value, {}, "Got empty hashref");

        $warnings = warnings { $one = $CLASS->from_method($obj, 'foo', '%') };
        like(
            $warnings->[0],
            qr/^Odd number of elements in anonymous hash\.?$/,
            "Not sure where to report warning"
        );

        is($one->exists,  1, "it does exist");
        is($one->defined, 1, "it is defined");
        is_deeply($one->value, {'foo' => undef}, "Scalar was wrapped in a hash");
    };
};

done_testing;

__END__

sub from_method {
    my $class = shift;
    my ($obj, $meth, $wrap) = @_;
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

    return bless(
        {
            EXISTS()    => 0,
            DEFINED()   => 0,
            EXCEPTION() => $err || "Unknown error",
        },
        $class
    ) unless $ok;

    return $class->from_return(\@out)
        if $wrap eq '@';

    return $class->from_return({@out})
        if $wrap eq '%';

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
    my $self = shift;

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

    if (ref($value)) {
        my $refa = render_ref($value);
        my $refb = "$value";

        my $val_string = $refa;
        $val_string .= "\n$refb" if $refa ne $refb;

        return Term::Table::Cell->new(
            value        => $val_string,
            border_left  => '>',
            border_right => '<',
        );
    }

    return Term::Table::Cell->new(
        value => "$value",
    );
}

1;
