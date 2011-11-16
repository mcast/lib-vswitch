#! perl

use strict;
use warnings;

use Test::More tests => 5;
use lib 't/tlib';

use_ok("Example::Removed"); # only present in v0.050
is(eval { Example::Removed->old_feature } || $@,
   'something quite useful', 'E:R->old_feature');

use_ok("Example::Shared"); # present in both 0.057 and 0.050
is($Example::Shared::VERSION, '0.050', '$Example::Shared::VERSION');

unlike(eval {
  require Example::Feature;
  "found $INC{'Example/Feature.pm'}";
} || $@, qr{^found }, 'E:F not present');
