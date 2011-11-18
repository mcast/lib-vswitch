#! perl

use strict;
use warnings;

use Test::More tests => 3;

use lib::vswitch;

my $path = eval { lib::vswitch->find(Example => '0.057') };
my $err = $@;
is($path, undef, 'v0.57: absent, lacking t/tlib');
isnt($err, undef, '   should error');

push @INC, 't/tlib';
$path = eval { lib::vswitch->find(Example => '0.057') };
$err = $@;
like($path,
     qr{lib-vswitch.*Example--0\.057}, # trying to avoid Un*x assumptions
     'Example via find')
  or diag("Error was '$err'");
