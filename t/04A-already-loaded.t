#! perl

use strict;
use warnings;

use Test::More tests => 8;
use lib 't/tlib';

=head1 DESCRIPTION

This covers "case A" in L<lib::vswitch/Avoid taking modules from two versions of a dist>.

=cut

# load from tlib
use_ok('Example::Shared');
is($Example::Shared::VERSION, '0.050', '$Example::Shared::VERSION');

my $try = eval q{use lib::vswitch Example => '0.057'; 'ok' } || $@;
isnt($try, 'ok', 'refuse switch to 0.057');
like($try, qr{0\.057.*Example::Shared.*0\.050}, 'refusal message');

# reload the module
my $old = delete $INC{'Example/Shared.pm'};
is_deeply(\@Example::Shared::WHENCE, [ $old ],
	  'compiled __FILE__ vs. %INC');
use_ok('Example::Shared');
is($INC{'Example/Shared.pm'}, $old,
   'reloads from same path');
is_deeply(\@Example::Shared::WHENCE, [ ($old) x 2 ],
	  'compiled twice from same __FILE__');
