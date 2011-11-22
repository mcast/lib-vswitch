use strict;
use warnings;
package lib::vswitch;

use File::ShareDir 'class_file';
use File::Spec;
use ExtUtils::Installed;


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

=head2 Avoid taking modules from two versions of a dist

Modules from one version of a dist may rightfully assume that other
modules from the same dist are of the same version.

Maintaining the validity of this assumption is something
L<lib::vswitch> should do, and ad-hoc version switching may not.

When the dist is B<not> already present on C<@INC>, we simply add a
dist no more than once.  This is mediated by L</%VSW> and L</uselib>.

Below are cases where the dist C<Foo> has version 1 already available
on C<@INC>, and the caller requests to C< uselib(Foo => 2) >

=over 4

=item A.

Module C<Foo::A> was loaded from C<Foo v1>.  Version switch to dist
C<Foo v2> makes a different version of C<Foo::A> available.

=item B.

Module C<Foo::B1> was loaded from C<Foo v1>.  Version switch to dist
C<Foo v2> makes available a C<Foo::B2> which expects C<Foo::B1> to
load from C<Foo v2> also.

=item C.

Version switch to dist C<Foo v2> - no modules loaded from C<Foo> yet.

Module C<Foo::C3> appears in both versions, but there is no problem
because the newer one is found and the old one is shadowed.  This is
otherwise like C<Foo::A> above.

If module C<Foo::C1> appears only in v1 and C<Foo::C2> appears only in
v2 (modules added to or removed from the dist), it becomes possible to
load either or both.  Each could reasonably expect a version match
with C<Foo:::C3>, and the absence of the module from the other
version.

=back

For A and B, it was too late to vswitch, so we should refuse to try.
For C, we must prevent the loading of modules from the shadowed dist.

Case A is simple to detect, though it needs some I/O.

Cases B and C requires the knowledge that C<Foo> dist contains, in
various versions, all of those modules; but without assuming that it
includes the entire C<Foo::> namespace.  This may be found by reading
the C<.packlist> if that is available, or for a vswitch-installed dist
by scanning the tree.

Packlists are often not available for Perl modules shipped with a
Linux distribution (and perhaps in other cases).

=head2 Support monkey-patching

Mechanisms to prevent accidental mixing of modules from different
versions may also make it harder to deliberately replace portions of
the dist.

This is undesirable, because the maintenance of this code was already
complicated before we got involved.  Better would be for the code
doing this to make it clear what is happening.

A likely solution is that the dist version being switched in has local
edits applied: C<< use lib::vswitch BioPerl => '1.2.3-patched' >>.

The "do not vswitch a dist twice" rule can be prevented by deleting
from L</%VSW>.  A neater way might be nice.

The "do not vswitch when the new tree contains an already-loaded
module" rule may need an override.  Possibly of the form C<use
lib::vswitch Foo => 2, -force_loaded => qr{^Foo::A$} >.


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

=back

and more in the managing of installations of dists

=over 4

=item *

It should be as easy to install another version as to install any
other dist.

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

  unless (defined $dist && defined $vsn && $dist ne '' && $vsn ne '') {
    require Carp;
    Carp::croak("Expected \$dist => \$version, got '$dist' => '$vsn'");
  }

  return if __vsw_take($dist, $vsn, 0); # idempotence

  my $path = $called->find($dist, $vsn);
  my @shadowed_loaded = $called->contains($path, keys %INC);
  if (@shadowed_loaded) {
    my @descr = map { $called->describe_file($_) } @shadowed_loaded;
    require Carp;
    local $" = ', ';
    Carp::croak("Cannot swtich dist '$dist' to version $vsn, would shadow already loaded modules: @descr");
  }

  my %used_dist = $called->file2dist(\%INC);
  if (defined (my $detail = $used_dist{$dist})) {
    my @descr = map { $called->describe_file($_) } keys %{ $detail->{incd} };
    my $info = ($detail->{packlist_file}
		? " (see $$detail{packlist_file})"
		: '');
    require Carp;
    local $" = ', ';
    Carp::croak("Cannot switch dist '$dist' to version $vsn, already loaded modules from another version$info: @descr");
  }

  return if __vsw_take($dist, $vsn, 1); # no multi-switch

  require lib;
  lib->import($path);
}

sub contains {
  my ($called, $lib_path, @rel_path) = @_;
  return grep {
    my $path = File::Spec->catfile($lib_path, $_);
    -e $path;
  } @rel_path;
}

sub describe_file {
  my ($called, $rel_path) = @_;
  # Describe $rel_path (likely, a key from %INC)
  # For debug purposes only.

  if ($rel_path =~ m{^[A-Za-z0-9_]+(/[A-Za-z0-9_]+)*\.pm$}) {
    # looks like a module (un*x assumption?)
    my $mod = $rel_path;
    $mod =~ s/\.pm$//;
    $mod =~ s{/}{::}g;
    my ($ok, $vsn) = eval {(1, $mod->VERSION)};
    return $ok ? qq{$mod v$vsn} : $mod;
  } else {
    return $rel_path;
  }
}

sub file2dist {
  my ($called, $inc) = @_;

  my %loaded; # key = path to report on, value = required name that loaded it
  my %unknown; # same, but dwindling keys
  %unknown = %loaded = reverse %$inc;

  # key = $dist, value = { incd => \%inc_subset }
  # plus another $dist='', listing modules of unknown providence
  my %out;

  # This does a lot of I/O.  EU:I->new can cache the result, but we
  # are about to change @INC, invalidating it.
  #
  # XXX: drive EU:I as incremental packlist finder, using inc_override
  # This would also let us see shadowed dists.
  #
  # XXX: realpath it; EU:I doesn't see packlist content in relative @INC ?
  # also need to realpath the packlist contents, to support (nonstandard?) relative packlist, such as in the test
  my $installed = ExtUtils::Installed->new;

  foreach my $distmod ($installed->modules) {
    # What EU:I calls "the module" maps exactly to what we call a dist
    my $dist = $distmod;
    $dist =~ s{::}{-}g;

    # Files in that dist.  (some more info available)
    my @files = $installed->files($distmod);
#    my $distmod_vsn = $installed->version($distmod); # undef: various reasons
#    my $packlist = $installed->packlist($distmod);
    my $packlist_file = $installed->packlist($distmod)->packlist_file;

    # Are any of them in %loaded?
    my @incd_files = grep { exists $loaded{$_} } @files;
    next unless @incd_files;

    my @double_dist = grep { !exists $unknown{$_} } @incd_files;
    warn "Unsettling... some files appear to belong to multiple dists\n".
      "(@double_dist)" if @double_dist;
    delete @unknown{@incd_files};

    # We couldn't store shadowed dists here anyway
    my %incd;
    my @inc_requested = @loaded{@incd_files};
    @incd{@inc_requested} = @incd_files;
    $out{$dist} = { incd => \%incd, packlist_file => $packlist_file };
  }

  # There is probably quite a lot of this from Perl itself,
  # but it is probably also where dist-conflicting files would end up
  $out{''} = { incd => { reverse %unknown } }
    if keys %unknown;

  #use YAML 'Dump'; warn Dump({ out => \%out, installed => $installed });
  return %out;
}

# Separated from uselib so subclass could share %VSW more neatly.
sub __vsw_take { # not a method
  my ($dist, $vsn, $write) = @_;
  if (defined $VSW{$dist} && $VSW{$dist} eq $vsn) {
    # already done it
    return 1;
  } elsif (defined $VSW{$dist}) {
    # prevent it
    require Carp;
    Carp::croak("Dist '$dist' already switched to version $VSW{$dist}, cannot also switch to version $vsn");
  } elsif ($write) {
    # record it
    $VSW{$dist} = $vsn;
    return 0;
  } else {
    # we would switch, unless we find another reason not to
    return ();
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


=head1 CAVEATS AND BUGS

There is no unimport via C<no>.  It is not clear that this could be
done safely.

=cut

sub unimport {
  die "Not implemented (unlikely to be safe)";
}

1;
