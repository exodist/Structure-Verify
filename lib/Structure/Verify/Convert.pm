package Structure::Verify::Convert;
use strict;
use warnings;

use Structure::Verify::Check();
use Structure::Verify::ProtoCheck();

use Structure::Verify::Check::Bag();
use Structure::Verify::Check::Boundary();
use Structure::Verify::Check::Custom();
use Structure::Verify::Check::Truthy();

use Structure::Verify::Check::Array();
use Structure::Verify::Check::Hash();
use Structure::Verify::Check::Object();
use Structure::Verify::Check::Ref();

use Structure::Verify::Check::Number();
use Structure::Verify::Check::Pattern();
use Structure::Verify::Check::ExactRef();
use Structure::Verify::Check::Regex();
use Structure::Verify::Check::String();
use Structure::Verify::Check::VString();

use Scalar::Util qw/blessed/;
use Structure::Verify::Util::Ref qw/rtype/;

use Importer Importer => 'import';
our @EXPORT_OK = qw{convert basic_convert relaxed_convert strict_convert};

sub basic_convert   { convert($_[0], $_[1], {use_regex => 1, implicit_end => 1}) }
sub relaxed_convert { convert($_[0], $_[1], {use_regex => 1, implicit_end => 0}) }
sub strict_convert  { convert($_[0], $_[1], {use_regex => 0, implicit_end => 0}) }

sub convert {
    my ($in, $state, $params) = @_;

    my ($file, $lines);
    if (blessed($in)) {
        if ($in->isa('Structure::Verify::Check')) {
            return $in unless $params->{implicit_end};
            return $in unless $in->can('set_bounded');
            return $in if defined $in->bounded;

            my $clone = $in->clone;
            $clone->set_bounded(1);
            return $clone;
        }

        if ($in->isa('Structure::Verify::ProtoCheck')) {
            $file  = $in->file;
            $lines = $in->lines;
            $in    = $in->raw;
        }
    }

    my %args = (via_build => 1);
    $args{lines} = $lines if $lines;
    $args{file}  = $file  if $file;

    my $type    = rtype($in);
    my $blessed = blessed($in) || "";

    my $build = sub {
        my ($type, $manage_state) = @_;

        my $new = $type->new(%args);
        my $new_state = $state;
        my $build = 1;

        # If we find recursion we do not build it, instead we make it a
        # boundless type check with no subchecks.
        if ($manage_state) {
            if ($state->{$in}) {
                $build = 0;
                $new->set_bounded(0) if $new->can('set_bounded');
            }
            else {
                $new_state = {%$state, $in => 1};
            }
        }

        if ($build) {
            $new->build($in);

            $new->set_bounded($params->{implicit_end} ? 1 : 0)
                if $new->can('set_bounded');
        }

        return ($new, $new_state);
    };

    # Non-refs are just treated as strings
    return $build->('Structure::Verify::Check::String', 0)
        unless $type;

    # If a blessed object is passed in we will check that we get the exact object.
    return $build->('Structure::Verify::Check::ExactRef', 0)
        if $blessed && $blessed ne 'Regexp';

    return $build->('Structure::Verify::Check::Array', 1)
        if $type eq 'ARRAY';

    return $build->('Structure::Verify::Check::Hash', 1)
        if $type eq 'HASH';

    return $build->('Structure::Verify::Check::Ref', 1)
        if $type eq 'SCALAR' || $type eq 'REF';

    return $build->('Structure::Verify::Check::Pattern', 0)
        if $type eq 'REGEXP' && $params->{use_regex};

    return $build->('Structure::Verify::Check::Custom', 0)
        if $type eq 'CODE' && $params->{use_code};

    return $build->('Structure::Verify::Check::ExactRef', 0);
}

1;
