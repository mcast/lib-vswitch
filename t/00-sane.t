#! perl

use strict;
use warnings;

END { BAIL_OUT("Sanity checks failed") if $? }
use Test::More tests => 4;

require_ok 'lib::vswitch';

is(eval { require Example::Switched; "$INC{'Example/Switched.pm'}" } || 'absent',
   'absent', 'tlib not already on @INC');

unshift @INC, 't/tlib';
require_ok 'Example::Switched';
is($Example::Switched::VERSION, '0.050', 'got default testmod');
