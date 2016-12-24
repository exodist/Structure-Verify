use Test2::Tools::Tiny;
use strict;
use warnings;

use Structure::Verify ':ALL';

ok(__PACKAGE__->can($_), "imported $_") for qw{
    build current_build

    run_checks

    check checks end etc

    load_check    load_checks
    load_check_as load_checks_as
};

load_check 'Hash';
load_checks qw/Array String/;
load_check_as 'Hash' => 'foo';
load_checks_as Array => 'bar', String => 'baz';

ok($INC{'Structure/Verify/Check/Container/Hash.pm'}, "Loaded hash");
ok($INC{'Structure/Verify/Check/Container/Array.pm'}, "Loaded array");
ok($INC{'Structure/Verify/Check/Value/String.pm'}, "Loaded string");

ok(my $meta = __PACKAGE__->STRUCTURE_VERIFY, "Got meta");

is_deeply(
    $meta->build_map,
    {
        hash => 'Structure::Verify::Check::Container::Hash',
        foo  => 'Structure::Verify::Check::Container::Hash',

        array => 'Structure::Verify::Check::Container::Array',
        bar   => 'Structure::Verify::Check::Container::Array',

        string => 'Structure::Verify::Check::Value::String',
        baz    => 'Structure::Verify::Check::Value::String',
    },
    "Set up our build map"
);

done_testing;

__END__

sub current_build() {
    my $meta = Structure::Verify::Meta->new(scalar caller);
    $meta->current_build;
}

sub build($$) {
    my @caller = caller(0);

    _build(\@caller, @_);
}

sub _build {
    my ($caller, $make, $with) = @_;

    my $meta = Structure::Verify::Meta->new($caller->[0]);

    my $class = $make =~ m/^\+(.*)$/ ? $1 : $meta->build_map->{$make};

    croak "Not sure how to build a '$make'"
        unless $class;

    my ($file, $lines);
    if (rtype($with) eq 'CODE') {
        my $info = sub_info($with);
        $file  = $info->{file};
        $lines = $info->{lines};
    }
    else {
        $file  = $caller->[1];
        $lines = [ $caller->[2] ];
    }

    my $check  = $class->new(file => $file, lines => $lines, via_build => 1);
    my $builds = $meta->builds;

    push @$builds => $check;
    my ($ok, $err);
    {
        local ($@, $?, $!);
        $ok = eval { $check->build($with, $make); 1 };
        $err = $@;
    }
    pop @$builds;

    die $err unless $ok;

    return $check;
}

sub check($;$) {
    my $check = pop;
    my $id = shift;

    my $meta = Structure::Verify::Meta->new(scalar caller);
    my $build = $meta->current_build or croak "No current build";

    return $build->add_subcheck($id => $check)
        if defined $id;

    return $build->add_subcheck($check);
}

my %CHECKS_REFS = (HASH => 1, ARRAY => 1);
sub checks($) {
    my $ref = shift;
    my $type = rtype($ref);

    croak "'checks' takes either a hashref or an arrayref"
        unless $CHECKS_REFS{$type};

    my $meta = Structure::Verify::Meta->new(scalar caller);
    my $build = $meta->current_build or croak "No current build";

    if ($type eq 'HASH') {
        $build->add_subcheck($_ => $ref->{$_}) for keys %$ref;
    }
    elsif ($type eq 'ARRAY') {
        $build->add_subcheck(@_) for @$ref;
    }
}

sub end() {
    my $meta = Structure::Verify::Meta->new(scalar caller);
    my $build = $meta->current_build or croak "No current build";

    croak "Current build '$build' cannot be bounded"
        unless $build->can('set_bounded');

    $build->set_bounded(1);
}

sub etc() {
    my $meta = Structure::Verify::Meta->new(scalar caller);
    my $build = $meta->current_build or croak "No current build";

    croak "Current build '$build' cannot be unbounded"
        unless $build->can('set_bounded');

    $build->set_bounded(0);
}

{
    no warnings 'once';
    *load_check      = \&load_checks;
    *load_check_as   = \&load_checks_as;
}

sub load_checks {
    my $meta = Structure::Verify::Meta->new(scalar caller);
    $meta->load(@_);
}

sub load_checks_as {
    my $meta = Structure::Verify::Meta->new(scalar caller);
    $meta->load_as(@_);
}

sub run_checks {
    my ($in, $want, %params) = @_;

    my $convert = $params{convert};
    my $in_path = $params{path} || '$_';

    my @todo  = ([$in_path || '', $want, Structure::Verify::Got->from_return($in)]);
    my $delta = Structure::Verify::Delta->new();
    my $pass  = 1;

    while (my $step = shift @todo) {
        my ($path, $check, $got) = @$step;

        $check = $convert->($check) if $convert;

        croak "$path: " . (defined($check) ? "'$check'" : "<undef>") . " is not a valid check"
            unless $check && $check->isa('Structure::Verify::Check');

        unless ($check->verify($got)) {
            $pass = 0;
            $delta->add($path, $check, $got);
            next;
        }

        if ($check->can('complex_check')) {
            my $ok = $check->complex_check(
                path    => $path,
                got     => $got,
                delta   => $delta,
                convert => $convert,
            );

            unless ($ok) {
                $pass = 0;
                next;
            }
        }

        unshift @todo => $check->subchecks($path, $got)
            if $check->can('subchecks');
    }

    return (1) if $pass;
    return (0, $delta);
}

1;
