#! perl

use strict;
use warnings;

use Test::More tests => 4;
use lib 't/tlib';

use lib::vswitch Example => '0.057';

use_ok("Example::Feature"); # only present in v0.057
is(eval { Example::Feature->sing_n_dance } || $@,
   'jigglejiggle', 'E:F->sing_n_dance');

use_ok("Example::Shared"); # present in both 0.057 and 0.050
is($Example::Shared::VERSION, '0.057', '$Example::Shared::VERSION');
