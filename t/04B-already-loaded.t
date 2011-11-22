#! perl

use strict;
use warnings;

use Test::More tests => 4;
use lib 't/tlib';

=head1 DESCRIPTION

This covers "case B" in L<lib::vswitch/Avoid taking modules from two versions of a dist>.

=cut

# load from tlib, module present in 0.050 but not 0.057
use_ok('Example::Removed');

my $try = eval q{use lib::vswitch Example => '0.057'; 'ok' } || $@;
isnt($try, 'ok', 'refuse switch to 0.057');
like($try, qr{0\.057.*Example::Removed v0\.050}, '  refusal message');

isnt(eval { require Example::Feature; 'loaded' } || $@,
     'loaded', 'module from 0.057 should not be available');
