#! perl

use strict;
use warnings;

use Test::More;

unless ($ENV{AUTHOR_TESTING}) {
  plan(skip_all => 'these tests are for testing by the author');
}


plan tests => 2;
my @hit = `git grep -nE '\\b([X]XX|[T]ODO)\\b' 2>&1`;
ok($? == 0x100 || $? == 0, "git grep exit code") or
  diag(sprintf('$?=0x%02x', $?));

# cleanup
for (my $i=0; $i<@hit; $i++) {
  if ($hit[$i] =~ m{^[^ :]+:\d+:\s*[T]ODO:\s*\{\s*$} &&
      $hit[$i+1] =~ m{\$[T]ODO}) {
    splice @hit, $i, 1; # remove the block label
  }
  if ($hit[$i] =~ m{[t]odo\.t:\d+:.*these are [T]ODO items}) {
    splice @hit, $i, 1;
  }
}

TODO: {
  local $TODO = 'these are TODO items';
  is((join '', "\n", @hit), "\n", 'matches');
}
