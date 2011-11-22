#! perl

use strict;
use warnings;

use Test::More tests => 4;
use lib 't/tlib';

require lib::vswitch;

# XXX: un*x assumptions here?
my @cases =
  (# [ file path, expect output ]
   [ 't/tlib/Example/Shared.pm', 'Example::Shared v0.050' ],
   [ 't/tlib/auto/share/module/lib-vswitch/Example--0.057/Example/Feature.pm',
     'Example::Feature' ]);

foreach my $C (@cases) {
  my ($path, $expect) = @$C;
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, "@_" };
  my $rel_path = $path;
  $rel_path =~ s{^.*?\b(Example[^-])}{$1};
  require $path;
  is(lib::vswitch->describe_file($rel_path), $expect, "describe $rel_path");
  is((join '', @warn), '', '  warnings during');
}
