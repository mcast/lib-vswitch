#! perl

use strict;
use warnings;

END { BAIL_OUT("Sanity checks failed") if $? }
use Test::More tests => 4;

require_ok 'lib::vswitch';

is(eval { require Example::Shared; "$INC{'Example/Shared.pm'}" } || 'absent',
   'absent', 'tlib not already on @INC');

unshift @INC, 't/tlib';
require_ok 'Example::Shared';
is($Example::Shared::VERSION, '0.050', 'got default testmod');
