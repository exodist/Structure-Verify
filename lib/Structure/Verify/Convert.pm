package Structure::Verify::Convert;
use strict;
use warnings;

use Structure::Verify::Check::Bag();
use Structure::Verify::Check::Boundary();
use Structure::Verify::Check::Compound();
use Structure::Verify::Check::Custom();
use Structure::Verify::Check::Truthy();

use Structure::Verify::Check::Container::Array();
use Structure::Verify::Check::Container::Hash();
use Structure::Verify::Check::Container::Object();
use Structure::Verify::Check::Container::Ref();

use Structure::Verify::Check::Value::Number();
use Structure::Verify::Check::Value::Pattern();
use Structure::Verify::Check::Value::Ref();
use Structure::Verify::Check::Value::Regex();
use Structure::Verify::Check::Value::String();
use Structure::Verify::Check::Value::VString();

use Scalar::Util qw/blessed/;
use Structure::Verify::Util::Ref qw/rtype/;

use Importer Importer => 'import';
our @EXPORT_OK = qw{convert};

sub convert {
    my ($in, $params) = @_;

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

    my $type = rtype($in);

    my $build = sub {
        my $type = shift;

        my $new = $type->new(%args);

        $new->build($in);

        $new->set_bounded($params->{implicit_end} ? 1 : 0)
            if $new->can('set_bounded');

        return $new;
    };

    return $build->('Structure::Verify::Check::Value::String')
        unless $type;

    return $build->('Structure::Verify::Check::Container::Array')
        if $type eq 'ARRAY';

    return $build->('Structure::Verify::Check::Container::Hash')
        if $type eq 'HASH';

    return $build->('Structure::Verify::Check::Value::Pattern')
        if $type eq 'REGEXP' && $params->{use_regex};

    return $build->('Structure::Verify::Check::Custom')
        if $type eq 'CODE' && $params->{use_code};

    return $build->('Structure::Verify::Check::Container::Ref')
        if $type eq 'SCALAR' || $type eq 'REF';

    return $build->('Structure::Verify::Check::Value::Ref');
}

1;
