#! perl

use strict;
use warnings;

use Test::More tests => 2;

use lib::vswitch;

my $path = eval { lib::vswitch->find(Example => '0.057') };
is(undef, $path, 'v0.57: absent, lacking t/tlib');

push @INC, 't/tlib';
$path = eval { lib::vswitch->find(Example => '0.057') };
like($path,
     qr{lib-vswitch.*Example--0\.057}, # trying to avoid Un*x assumptions
     'Example via find');
