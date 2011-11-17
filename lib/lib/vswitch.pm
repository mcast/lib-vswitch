use strict;
use warnings;
package lib::vswitch;

use File::ShareDir 'class_file';

=head1 NAME

lib::vswitch - @INC switch to select another version


=head1 SYNOPSIS

 # In the calling code
 use lib::vswitch BioPerl => '1.2.3';
 use Bio::AlignIO;

 # XXX: describe how it gets there


=head1 DESCRIPTION

This module adds to C<@INC> the necessary directories for a specific
version of a distribution.

It also takes steps to ensure scripts loading multiple modules do not
inadvertently attempt to use two different versions of a distribution
simultaneously.


=head1 RATIONALE

This is yet-another module messing with C<@INC>.  There should be a
good reason.

Nearby I find several applications which depend on a specific version
of some distributions of modules.  These dependencies are maintained
in several ways.

=head2 Alternatives

=over 4

=item *

Write the app to assume the latest version of a module, within some
range.  Make this explicit in the C<use> when there is a known bug.

With this, version requirements increase gently upwards.  Much of CPAN
operatees in this way.

Problems start when the new version of a module removes some feature
and you lack the time to work around, re-implement or test for the new
version; or you use a locally hacked version and the changes do not
make it upstream.

Once you are stuck on an old version, there might be no incentive to
upgrade and it could require an increasing amount of work.

=item *

Write the app to use whichever version it finds itself presented with,
in a backwards- or forwards-compatible way, using the documented
replacements for deprecated calls etc..

I mention this option for completeness.  If your code was doing that,
you wouldn't be reading this.

=item *

You can "roll your own" during app installation: install the version
you need and make sure nobody upgrades it.

We often do this, in various ways.  It is quick and easy.

When the application with the version requirement is a collection of
modules (a "dist"), it may have callers which also need and provide
the same module.  Will they use the correct version?  Would your code
notice if it didn't?

The C<use> function doesn't provide for a "maximum version" so you are
on your own at this point.

There may be a perfectly usable copy of the modules you want already
on C<@INC>, but while you need to force the use of a known-version
copy it will be difficult to take advantage of that.

=item *

Build something over L<Module::PortablePath> and use tags of the form
C<ensembl62> .

These tags must be maintained (in our case, by the central authority
via a helpdesk ticket).  You need a new one for each version.

What happens if a script brings in ensembl62 and then later adds
ensembl63?

How do you know when ensembl47 is no longer used?

=item *

Distributions which are well known to have dependent applications
using specific versions could provide explicit support to do this.

This could reduce the repetition down to approximately the number of
dists used this way, but only where and when the dist authors care to
add support.

=back

In short, the problem can be managed but it takes some effort.

=head2 Problems to solve

From the list above, there are some common problems on the application
side

=over 4

=item *

Prevent the simultaneous import of two versions of the same dist.

=item *

Allow safe sharing of known-version dist install trees.

=item *

It should be as easy to install another version as to install any
other dist.

=back

and more in the managing of installations of dists

=item *

Installed versions should be enumerable.

=item *

It would be very useful to enumerate dependent applications.
Preferably without waiting for them to be run, in order to hook the
version switching call.

XXX: Here the L<Module::PortablePath> tag solution may be superior
because it uses one symbol-shaped string to declare the dependency.

=item *

Bonus points for making the often-used set of known-version dists easy
to install via L<CPAN>.

=back

=head2 Problems remaining

The freezing of module version requirements in otherwise-living code
is itself a problem.

Will making it easier to manage the knock-on problems make that worse?


=head1 PACKAGE GLOBALS

=head2 %VSW

This hash is used to prevent the use of different versions of the same
dist.

It is offered as part of the public API for this module to improve
transparency.  Keys are dist names, values are the versions set by
L</uselib>.

Writing to it is likely to cause problems.

=cut

our %VSW; # key = dist, value = version string


=head1 CLASS METHODS

These are not particularly intended for normal use by client code, but
might form some useful building blocks.

=head2 find($dist, $vsn)

Return the path for the specified version of the named dist.

This is based on L<File::ShareDir/class_file> and so should respect
subclassing of L<lib::vswitch> (XXX: untested).

=cut

sub find {
  my ($called, $name, $vsn) = @_;
  my $inst = eval { $called->class_file("$name--$vsn") };
  my $err = $@;
  if (!defined $inst) {
    require Carp;
    Carp::croak("$called cannot find $name version $vsn: $err");
  } else {
    return $inst;
  }
}


=head2 uselib($dist, $vsn)

Discover the new path using L</find>, then ask L<lib> to add it to
C<@INC> .

This checks and updates L</%VSW> to prevent multiple C<uselib> of the
same dist.

=cut

sub uselib {
  my ($called, $dist, $vsn) = @_;

  return if __vsw_take($dist, $vsn); # idempotence
  my $path = $called->find($dist, $vsn);
  require lib;
  lib->import($path);
}


# Separated from uselib so subclass could share %VSW more neatly.
sub __vsw_take { # not a method
  my ($dist, $vsn) = @_;
  if (defined $VSW{$dist} && $VSW{$dist} eq $vsn) {
    # already done it
    return 1;
  } elsif (defined $VSW{$dist}) {
    # prevent it
    require Carp;
    Carp::croak("Dist '$dist' already switched to version $VSW{$dist}, cannot also switch to version $vsn");
  } else {
    # record it
    $VSW{$dist} = $vsn;
    return 0;
  }
}


=head2 import(...)

This does the work when you write something like

 use lib::vswitch 0.73 BioPerl => '1.2.3';
 # 0.73 would be a minimum version for lib::vswitch itself.
 
 use lib::vswitch 'Foo-Bar' => '0.05-hacked';

Currently it takes one ($dist => $vsn) pair and calls L</uselib> with
them.

Extra flags or the ability to C<uselib> multiple pairs may be added
later.

=cut

sub import {
  my ($called, @arg) = @_;

  if (0 == @arg) {
    # nothing to do
  } elsif (2 == @arg) {
    $called->uselib(@arg);
  } else {
    require Carp;
    Carp::croak("Syntax: use $called 'Dist-Name' => 'version-string'");
  }
}

1;
