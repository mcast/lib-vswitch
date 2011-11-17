#! perl

use strict;
use warnings;

use Test::More tests => 7;
use lib 't/tlib';

use lib::vswitch Example => '0.057';

use_ok("Example::Feature"); # only present in v0.057
is(eval { Example::Feature->sing_n_dance } || $@,
   'jigglejiggle', 'E:F->sing_n_dance');

use_ok("Example::Shared"); # present in both 0.057 and 0.050
is($Example::Shared::VERSION, '0.057', '$Example::Shared::VERSION');

TODO: {
  local $TODO = 'no shadow warnings yet';
  fail('E:S present in both - should raise eyebrows');
}

TODO: {
  local $TODO = 'no load prevention yet for unshadowed dist module';
    unlike(eval {
      require Example::Removed;
      "found $INC{'Example/Removed.pm'}";
    } || $@, qr{^found }, 'E:R should not be found');
}

isnt(eval "no lib::vswitch; 'ok'" || $@,
     'ok', "Unimport is not implemented");
