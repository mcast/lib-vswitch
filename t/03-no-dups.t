#! perl

use strict;
use warnings;

use Test::More tests => 9;
use lib 't/tlib';

require lib::vswitch;

is($lib::vswitch::VSW{'Example'}, undef, '$VSW{Example} before');
is(eval { lib::vswitch->import(Example => '0.046'); 'ok' } || $@,
   'ok', 'vswitch Example 0.046');
use_ok('Example::Ancient');
is($Example::Ancient::VERSION, '0.046', 'E:A version');

like(eval { lib::vswitch->import(Example => '0.057'); 'ok' } || $@,
     qr{already.*0\.046}, 'vswitch Example again: refuse 0.057');
isnt(eval { require Example::Feature; 'ok' } || $@,
     'ok', 'E:F should not be present');

is($lib::vswitch::VSW{'Example'}, '0.046', '$VSW{Example} after');

my $old_INC = join ':', @INC;
is(eval { lib::vswitch->import(Example => '0.046'); 'ok' } || $@,
   'ok', 'vswitch again: Example 0.046');
is((join ':', @INC), $old_INC, '  was nop: @INC unchanged');

# XXX: allows the something else to load
