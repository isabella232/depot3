# Packages in d3

([Table of contents](TOC#table-of-contents))

A package in d3 is a package in Casper. d3 stores extra data about packages, which provide enhancements over standard Casper package handling, such as [automatic updates](#sync), [conditional installs](#conditional-installs), [piloting](#piloting), [expiration](#expiration), and so on.

A d3 package has all the attributes of a Casper package, plus those listed here. While it's possible to edit the Casper attributes via Casper Admin or the JSS web UI, we recommend using [d3admin](#d3admin) for all work with d3 packages, since d3admin will help enforce data-integrity. 


## status

As a package spends time in d3, its status will change. These are the statuses:

### pilot

  Packages that are newer in d3 than the currently [live](#live) package for their [basename](#basename).
  
  All packages are pilots when first added to d3. Pilots can be installed on clients using the
  'd3 pilot' command with the [edition](#edition).

### live

  Once a package has been [piloted](#piloting) and is ready for full deployment, 
  it is released by making it 'live'.
  
  There can only be one live package per [basename](#basename) at a time, and using a basename to refer
  to a package will always yield the currently live one (if any). 
  
  Once made live, the package will be the one installed when the '[d3](#d3) [install](#installing) _basename_' command is given. 
  
  The package will be automatically installed at the next '[d3](#d3) [sync](#sync)' on any machine
  where the basename is already installed and is not in pilot, or where the machine is in one of 
  the [auto-install computer groups](#auto-groups).

### deprecated

  A package that was once live, but has been superceded by a newer edition of it's
  basename being made live.

### skipped

  A package that is older than the currently live one for its basename, but was never
  made live itself.


## auto groups

These are Casper computer groups (static or smart) whose members automatically get certain packages installed at the next '[d3](#d3) [sync](#sync)'. 

Packages in d3 have an attribute 'auto_groups' that contains a list of computer groups whose members should get this package automatically.  When d3 is [syncing](#sync), it looks for any live packages whose auto-groups contain the machine doing the sync, and installs them if needed.

### standard auto-installs

There is a special, pseudo-group-name used for auto-grouping called 'standard'. When a packages has the auto-group 'standard' it is auto-installed on _all_ d3 client computers.

See also: [sync](#sync)



## excluded groups

Casper computer groups (static or smart) whose members are normally prohibitied from installing certain pacakges. Packages in d3 have an attribute 'excluded_groups' that contains a list of computer
groups whose members should never get this package.  Such packages don't even show up as available for machines in those groups. If [force](#force) is used the packages can be listed and installed.

See also: [force](#force)

## pre- and post- scripts

While .pkg installers might have internal pre- and post- install scripts, .dmg installers do not.  Also, while
Casper policies can run Casper scripts before and after package (un)installation, the (un)installation can't easily
be stopped if the pre- script fails.

d3 provides pre- and post-install, and pre- and post-remove scripts. These scripts are also just Casper scripts, and they are run via the 'jamf runScript' command.

When a d3 pre-install script runs, it's exit status must be 0 (zero - success) or else the package won't be installed.

Similiarly when a d3 pre-remove script runs, if it's exit status is not zero, it won't be uninstalled.

### exit status 111 on pre- scripts
Both pre-install and pre-remove scripts cause special behaviour when their exist status is 111:

* If the pre-install script exits 111, the package will NOT be installed, but the d3 [receipt](#receipts) will be written as if it were.

  A possible use-case for this is the CrashPlan client. Crashplan has its own client-update mechanism
  that happens from it's own servers.
  
  If some version of CrashPlan is initially installed via d3, the
  pre-install script for the next version might check to see if Crashplan has already been updated by
  its own server, and in that case, it exits 111, and d3 writes its receipt so that it knowns
  things are up-to-date. On machines that don't have crashplan installed at all, the script can do
  whatever pre-install actions it wants (such as putting customization files in place) and then exit
  0 to allow a normal install to happen.

* If the pre-remove script exits 111, the 'jamf uninstall' will not be run, but the d3 receipt will be removed.

  A use-case here is an application for which  there's an 'uninstaller' app or pkg.
  
  A regular d3/jamf uninstall will just remove the files that were originally installed, but the
  uninstaller provided by the app's developer might remove many other things, or do so in a way that
  doesn't break other products.
  
  In this case, the pre-remove script can just run the developers uninstaller, and then exit 111, which
  causes d3 to remove its receipt and do no more.


## prohibiting process

Packages can be configured with the name of a process which, if running at install time, prevents installation.

The process name is compared to the output of `/bin/ps -A -c -o comm` and if it matches any whole line of that output, the process is considered to be running, and be package isn't installed.


## remove first

If this attribute is true, then before installing the package, any previously installed version of the same basename is [uninstalled](#uninstalling) first. 


## os limitations

This is the casper 'os limitations' setting. It is enhanced by the JSS module's ability to understand "minimum OS" in the format ">=10.9.5"


## expiration

Expiration is d3's ability to automatically uninstall packages that haven't been used in some period of days. "Use" means the app has been in the foreground.

At the highest level, expiration is controled by the `client_expiration_allowed` key of the d3 configuration file
on every client. If that key is not true, no expiration ever happens.

If expiration is allowed, it is expected that [d3RepoMan](#d3RepoMan) is installed and properly running on each client. d3RepoMan records a timestamp into a plist every time an App is brought to the foreground in them GUI. See [d3RepoMan](#d3RepoMan) for more details.

Packages have two attributes related to expiration:

* expiration

  This is an integer representing the number of days of disuse required before a package is expired. For example, if the expiration is 30, the package will be removed after 30 days of disuse. Setting the expiration to zero (the default) means the package never expires.

* expiration_path

  This is the path to the executable that must come to the foreground to be counted as "use"

  For example,  a package might install /Applications/Foobar.app, withs an expiration of 20, and and expiration_path of /Applications/Foobar.app/Contents/MacOS/Foobar

Several things must be true before a package is ununstalled:

- The client must have expirations allowed
- The package must be removable
- The package must have an expiration > 0
- The package must have an expiration_path defined
- The last time the expiration_path came to the foreground must be within the expiration period
- d3 must be able to connect to the JSS and the database.
- The expirpation_path cannot be in the list of currently-running processes
- [d3RepoMan](#d3RepoMan) must be running
- The usage-tracking plists must be up-to-date

If any of these is not true, the package is not uninstalled.

([Table of contents](TOC#table-of-contents))
