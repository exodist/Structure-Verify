package Structure::Verify::Autoload;
use strict;
use warnings;

use Structure::Verify::Meta;
use Module::Pluggable search_path => ['Structure::Verify::Check'], require => 1;

my %ALIASES = map {
    my $mod = $_;
    map {($_ => $mod)} $mod->BUILD_ALIAS;
} __PACKAGE__->plugins;

sub import {
    my $class = shift;
    my $caller = caller;

    my $meta = Structure::Verify::Meta->new($caller);

    $meta->set_use_autoload(1);
}

sub find {
    my $class = shift;
    my ($alias) = @_;
    return $ALIASES{$alias};
}

1;
