package is;
use strict;
use warnings;

use Test2::Tools::Tiny;

use Test2::API qw/context/;
use Structure::Verify::Convert qw/relaxed_convert basic_convert/;
use Carp qw/croak/;

use Structure::Verify ':ALL';
use Structure::Verify::Builders(
    qw{ hash array object bag },
);

our @EXPORT = qw{
    ok is isnt like unlike diag note skip_all todo plan done_testing warnings
    exception tests capture hash array object bag check checks check_pair end
    etc is_deeply
};

sub import {
    my $class = shift;
    my @import = @_;
    my $caller = caller;

    @import = @EXPORT unless @import;

    my $meta = Structure::Verify::Meta->new($caller);

    for my $name (@import) {
        no strict 'refs';
        *{"$caller\::$name"} = $class->can($name) or croak "'$name' is not a valid import";
    }
}

no warnings qw/prototype redefine/;

sub is($$;$) {
    my ($ok, $delta) = run_checks($_[0], $_[1], convert => \&basic_convert);
    my $ctx = context;
    ok($ok, $_[2]) || diag map {"$_\n"} $delta->term_table->render;
    $ctx->release;
    return $ok;
}

sub like($$;$) {
    my ($ok, $delta) = run_checks($_[0], $_[1], convert => \&relaxed_convert);
    my $ctx = context;
    ok($ok, $_[2]) || diag map {"$_\n"} $delta->term_table->render;
    $ctx->release;
    return $ok;
}

1;
