#! perl

use strict;
use warnings;

use Test::More tests => 8;
use lib 't/tlib';

require lib::vswitch;

# do the sneaky
my $path = lib::vswitch->find(Example => '0.057');
push @INC, $path; # on the end - like it was lurking in PERL5LIB
is($lib::vswitch::VSW{'Example'}, undef, '$VSW{Example} does not know yet');

# ask vswitch to do it
my @warn;
my $old_INC = join ':', @INC;
my $try = eval {
  local $SIG{__WARN__} = sub { push @warn, "@_" };
  lib::vswitch->import(Example => '0.057');
  'ok';
} || $@;
is($try, 'ok', 'vswitch Example 0.057');

TODO: {
  local $TODO = 'should warn';

  is(scalar @warn, 1, '  one warning');
  like("@warn", qr{Path .* already .* Example 0\.057}, '  vswitch complains');
}

TODO: {
  local $TODO = 'probably should leave @INC alone';
  # Currently, "use lib" bumps the sneaked path to the front of @INC
  # This has implications for the shadowing check...
  is((join ':', @INC), $old_INC, '  was nop: @INC unchanged');
}

is($lib::vswitch::VSW{'Example'}, '0.057', '$VSW{Example} after');


TODO: {
  local $TODO = 'not yet tested';
  fail('sneaking via symlink; or more likely the vswitch auto path is a symlink'); # $^O permitting
  fail('sneaking a different version, thereby foiling %VSW');
}
