# Glossary of d3 terms and concepts


## Table of Contents

* [Basic terms](#basic-terms)
  * [pilot & live](pilot--live) 
  * [basename](#basename)
  * [version](#version)
  * [revision](#revision)
  * [edition](#edition)

* [Packages](#packages)
  * [status](#status)
  * [auto groups](#auto-groups)
  * [excluded groups](#excluded-groups)
  * [pre- and post- scripts](#pre-and-post-scripts)
  * [prohibiting process](#prohibiting-process)
  * [remove first](#remove-first)
  * [os limitations](#os-limitations)
  * [expiration](#expiration)

* [Client](#client)
  * [d3](#d3)
  * [receipts](#receipts)
  * [installing](#installing)
    * [piloting](#piloting)
    * [conditional installs](#conditional-installs)
    * [uninstalling](#uninstalling)
  * [sync](#sync)
  * [force](#force)
  * [d3RepoMan](#d3RepoMan)
  * [puppytime](#puppytime)
    * [puppy queue](#puppy-queue)
  * [casper policies and scripts used by d3](#casper-policies-and-scripts-used-by-d3)

* [Admin](#admin)
  * [d3admin](#d3admin)
    * [add](#add)
    * [edit](#edit)
    * [make live](#make-live)
    * [delete](#delete)
    * [package lists](#package-lists)
    * [reports](#reports)


* [Configuration](#configuration)
  * [jss_gem.conf](#jssgemconf)
  * [d3.conf](#d3conf)
  * [d3amin and your keychain](#d3admin-and-your-keychain)

## Basic terms

### pilot & live

When packages are added to d3, they are "in pilot". This means they are not available to the ["d3 install"](#installing) command, and won't be [automatically installed](#auto-groups) or used for [updating](#sync)  even though they are on the server.  They can be manually installed via the ["d3 pilot"](#piloting) command, for testing purposes.

After testing, the package can be [made live](#make-live), i.e. released.  This makes them available to ["d3 install"](#installing) and [syncing a client](#sync) will auto-install if needed, and update any previously installed package for the same [basename](#basename). Only one package at a time can be live for a [basename](#basename).

See also: [status](#status), [installing](#installing), [piloting](#piloting), [admin](#admin) 

([Top](#table-of-contents))

### basename

A basename in d3 is a word used to identify all packages that install any version of the same thing. For example "transmogrifier" could refer to all packages in d3 that install any version of Transmogrifier.app. When a basename alone is used to specify a package, it always refers to the
currently live package for the basename. 

([Top](#table-of-contents))

### version

This is the version of the thing installed by a package. A package that installs Transmogrifier might
install version 2.1.2, while another package that installs Transmogrifier might install version 2.2.3.
Versions can include any alpha-numeric characters, e.g. "12.5a3"

([Top](#table-of-contents))

### revision

This is an integer representing a sequential addition to d3 of the same version of a basename. Let's say
Transmogrifier 2.2.3 is added to d3 for the first time, it's revision will be 1.  If later a problem is
discoverd with the .pkg itself, and a new .pkg is created for version 2.2.3, when added to d3, it will
have the revision 2.  This can also be used for differentiating different builds of an item, or
build numbers can be included in the version.

([Top](#table-of-contents))

### edition

The edition is one of the most important concepts in d3. It is a combination of basename, version, and revision of a package, joined by hyphens. It must be unique for each package in d3.

For example, there might be three editions of the basename 'transmogrifier' in d3 at the same time:  transmogrifier-2.1.2-1, transmogrifier-2.1.2-2, and transmogrifier-2.2.3-1. When specifying any package that isn't [live](#live), the edition is used to identify it.

See also: [status](#status)

([Top](#table-of-contents))

## Packages

A package in d3 is a package in Casper. d3 stores extra data about packages, which provide enhancements over standard Casper package handling, such as [automatic updates](#sync), [conditional installs](#conditional-installs), [piloting](#piloting), [expiration](#expiration), and so on.

A d3 package has all the attributes of a Casper package, plus those listed here. While it's possible to edit the Casper attributes via Casper Admin or the JSS web UI, we recommend using [d3admin](#d3admin) for all work with d3 packages, since d3admin will help enforce data-integrity. 

([Top](#table-of-contents))

### status

As a package spends time in d3, its status will change. These are the statuses:

#### pilot

  Packages that are newer in d3 than the currently [live](#live) package for their [basename](#basename).
  
  All packages are pilots when first added to d3. Pilots can be installed on clients using the
  'd3 pilot' command with the [edition](#edition).

#### live

  Once a package has been [piloted](#piloting) and is ready for full deployment, 
  it is released by making it 'live'.
  
  There can only be one live package per [basename](#basename) at a time, and using a basename to refer
  to a package will always yield the currently live one (if any). 
  
  Once made live, the package will be the one installed when the '[d3](#d3) [install](#installing) _basename_' command is given. 
  
  The package will be automatically installed at the next '[d3](#d3) [sync](#sync)' on any machine
  where the basename is already installed and is not in pilot, or where the machine is in one of 
  the [auto-install computer groups](#auto-groups).

#### deprecated

  A package that was once live, but has been superceded by a newer edition of it's
  basename being made live.

#### skipped

  A package that is older than the currently live one for its basename, but was never
  made live itself.

#### archived

  A package that has been removed from d3, but its metadata (and possibly the actual installer file)
  is still available in the d3 archive.

NOTE: The age of packages relative to each other is determined by their JSS id number, which is
an every-increasing integer as packages are added to Casper.
If the id number is higher, the package is newer.

([Top](#table-of-contents))

#### auto groups

These are Casper computer groups (static or smart) whose members automatically get certain packages installed at the next '[d3](#d3) [sync](#sync)'. 

Packages in d3 have an attribute 'auto_groups' that contains a list of computer groups whose members should get this package automatically.  When d3 is [syncing](#sync), it looks for any live packages whose auto-groups contain the machine doing the sync, and installs them if needed.

##### standard auto-installs

There is a special, pseudo-group-name used for auto-grouping called 'standard'. When a packages has the auto-group 'standard' it is auto-installed on _all_ d3 client computers.

See also: [sync](#sync)

([Top](#table-of-contents))


#### excluded groups

Casper computer groups (static or smart) whose members are normally prohibitied from installing certain pacakges. Packages in d3 have an attribute 'excluded_groups' that contains a list of computer
groups whose members should never get this package.  Such packages don't even show up as available for machines in those groups. If [force](#force) is used the packages can be listed and installed.

See also: [force](#force)

([Top](#table-of-contents))

#### pre- and post- scripts

While .pkg installers might have internal pre- and post- install scripts, .dmg installers do not.  Also, while
Casper policies can run Casper scripts before and after package (un)installation, the (un)installation can't easily
be stopped if the pre- script fails.

d3 provides pre- and post-install, and pre- and post-remove scripts. These scripts are also just Casper scripts, and they are run via the 'jamf runScript' command.

When a d3 pre-install script runs, it's exit status must be 0 (zero - success) or else the package won't be installed.

Similiarly when a d3 pre-remove script runs, if it's exit status is not zero, it won't be uninstalled.

##### exit status 111 on pre- scripts
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


([Top](#table-of-contents))


### prohibiting process

Packages can be configured with the name of a process which, if running at install time, prevents installation.

The process name is compared to the output of `/bin/ps -A -c -o comm` and if it matches any whole line of that output, the process is considered to be running, and be package isn't installed.

([Top](#table-of-contents))


### remove first

If this attribute is true, then before installing the package, any previously installed version of the same basename is [uninstalled](#uninstalling) first. 


([Top](#table-of-contents))

### os limitations

This is the casper 'os limitations' setting. It is enhanced by the JSS module's ability to understand "minimum OS" in the format ">=10.9.5"

([Top](#table-of-contents))


### expiration

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

([Top](#table-of-contents))



## Client

A d3 client is both the executable 'd3' command, as well as a computer that uses it to do local package management.

### d3

The `d3` command is the heart of d3 and us used for [piloting](#piloting), [installing](#installing), [uninstalling](#uninstalling), [syncing](#sync), and generating various lists and info. Use `d3 help` to see the help screen. Most use of d3 must be done as root. 

The general form of a d3 commandline is `d3 [options] command [argument [...]]`

- A command is always required, and tells d3 what you want to do, e.g. 'install', 'sync', 'list-available', and so on.
- The argument(s) are thing or things you want to perform the command with
- The options can change the behavior of the command, or provide extra info.

For detailed documentation of all commands and options, see [TODO: add this link](d3-man-page)

([Top](#table-of-contents))

### receipts

d3 keeps track of what's installed by maintaining a set of receipts on the local disk. These receipts are separate from the JSS package receipts, and also different from the Apple package receipt system available via `pkgutil`. A d3 receipt stores all info needed to work with the package after installation. 

([Top](#table-of-contents))


### installing

d3 has two commands that install packages: install and pilot.

Most normal installation is done with the install command: `d3 install basename`.

This causes the currently [live](#status) package for the basename to be installed. More than one basename can be provided, all will be installed.

During installation, d3 will first check that no [prohibiting process](#prohibiting-process) is running, and then will uninstall older versions of its basename if the remove-first attribute is true. Then d3 will run any [pre-install script](#pre-and-post-scripts). If the script exits successfully, the package is installed using `jamf install` and if the install was successful, any [post-install script](#pre-and-post-scripts) is run.

In order to install, d3 needs to know the name of a non-root 'admin' who is doing the install. If d3 can't figure out a name on it's own, it must be provided with the -a/--admin option.  

#### piloting

In order to test packages before they are made live, install them with the 'pilot' command: `d3 pilot edition` 

d3 will then install the [pilot](#status) package indicated by the [edition](#edition) as described above. 

However! Once a package is in pilot, the [sync](#sync) process will stop auto-updating that basename. The only exception to this is when the edition being piloted becomes live, in which case the receipt for the pacakge is modified to reflect that, and the package is no longer in pilot.

If a package is in pilot on some machine, and some other, newer package becomes live, that machine will _never_ get any new version of the basename until someone uninstalls the pilot with `d3 depilot edition`. 

It is ultimately the responsibility of the admin doing the piloting to ensure clients are depiloted as needed. To help with this, [d3admin](#d3admin) can generate reports of clients that are piloting packages.

#### conditional installs

See [pre- and post- scripts](#pre-and-post-scripts) for a discussion of conditional installs and uninstalls, as well as the special meaning of scripts exiting with status 111.


#### uninstalling

If a package is marked as removable, then `d3 uninstall basename` will uninstall it.  To uninstall pilots, you must use `d3 depilot basename`


([Top](#table-of-contents))


### sync

Syncing is the heart of d3's automation. When the command `d3 sync` is run on a client, these things happen:

* Receipts are updated if needed

  If any changes were made to packages on the server, which affect the package as installed on the client,
  those changes are updated in the receipt on the client. Such changes include removability, expiration path,
  expiration period, etc.

  See also: [receipt](#receipt)

* Pilots are 'enlivened' if needed.

  If some package is installed as a pilot, and that exact edition becomes live, then the receipt for
  the pilot installation will be updated to show that the package is now live, without needing
  to re-install the package.

  See also: [piloting](#piloting)

* Installed basenames are updated, if needed

  For all installed non-pilot packages, if the currently-live edition for that basename is newer
  than the installed edition, the new one is installed. If the new one is set to uninstall older versions
  first, then the existing one will be uninstalled just before the new one is installed.

* New scoped packages are installed

  Any newly-available live package on the server which has one of this machine's groups in its auto-groups list, is
  installed. This could happen because a new basename became live, or because the auto-groups for a package
  changed, or because the machines group memberships have changed.

  See also: [auto groups](auto groups)

* Expiration happens

  All receipts are compared to current d3RepoMan data to see if expiration should happen. If so, the
  package us uninstalled and any expiration policies defined are executed.

  See also: [expiration](#expiration)

Syncing is controled by a launchd job to run at regular intervals, but can be run manually any time with `d3 sync`. 

([Top](#table-of-contents))

### scoping

d3 itself provides basic scoping via the [auto-groups](#auto-groups) and [excluded-groups](#excluded-groups). This can handle most of the scoping needs for most packages. 

If more complex scoping is needed, one method is to assign no auto- or excluded-groups, and use a fully-scoped Casper policy to perform the ['d3 install'](#installing) command.

([Top](#table-of-contents))

### force

The --force/-f option to d3 causes it to do many things that it wouldn't normally do. 

For example, if a package is excluded for one of the machine's groups, it can still be installed or piloted with --force. 

Excluded packages normally don't show up in the list of available packages, but --force will cause all packages to be listed.

([Top](#table-of-contents))


### d3RepoMan

d3RepoMan is a background process that locally records a timestamp every time an application comes to the foreground in the machine's UI. It is required to use d3's [expiration]#(expiration) feature, and it allows the use of that feature without turning on Casper's 'application usage logging', which stores that data on the server. 

The process is launched by a machine-wide Launch Agent, and runs as the user logged in. It writes a different plist for each user in the directory /Library/Application Support/d3/Usage.  Those plists are used by the [sync](#sync) process as it performs expirations. 

([Top](#table-of-contents))

### puppytime

Some packages require a reboot after they are installed. d3 handles these using a system called 'puppytime' - a name inherited from a tool used by Pixar to automate such installations long before d3 was written. The original tool would display a slide-show of cute puppy images while the installation(s) were happening, after logout and before reboot.

When d3 'installs' a package requiring reboot, info about the package is added to the 'puppy queue' and a Casper policy of your choice is executed. The policy should somehow notify the user to log out as soon as possible to perform the installs. 

At logout, a process runs which examines the queue, and installs all the packages there, while displaying a slideshow of images. 

The default images that come with d3 are still puppies, however they can be customized easily. 

([Top](#table-of-contents))


#### puppy queue

The contents of the puppy queue can be listed with with `d3 list-queue` and items therein can be removed with `d3 dequeue basename`

### casper policies and scripts used by d3

Several things in d3 can be customised by way of Casper policies. 

- Packages added to the puppy queue: a policy is triggered to handle notification and any other tasks desired.





#### environment variables

([Top](#table-of-contents))


## Admin


### d3admin

d3admin is a command-line tool for working with d3 packages on the server. Admins who maintain d3 packages will use it to add, edit, and delete packages, as well as make them live and get reports about them.

d3admin cannot be run as root, since it needs to know who's doing things to the packages on the server.

The first time you run d3admin, it will ask you for host and authentication info for the JSS API, the JSS's MySQL server, and the read-write password for the Master Distribution Point. It will store this data in your keychain, so you won't need to enter it every time you use d3admin. If you ever need to update this data, just use `d3admin --config`. See also: [configuration](#configuration)

The general command-line format for d3admin is `d3admin action target(s) [options]` There are two modes for using d3admin: walkthru and command-line. 

#### walkthru

When the --walkthru/-w option is is given, d3admin will prompt for a [basename](#basename), [edition](#edition) or other data as needed. If using walkthru for adding or editing a package, it will present a menu of choices for setting the attributes of the package, warning you if invalid data is given. When you're ready to save your changes, you'll be asked for confirmation.

For example `d3admin add -w transmogrifier` will present a menu of choices for adding a new [pilot](#status) package to d3 with the [basename](#basename) 'transmogrifier'. `d3admin edit -w` will prompt for a [basename](#basename) or [edition](#edition) before displaying the menu.

This mode is the easiest to use when manually adding or editing packages.

#### command-line

Every attribute of a package, and other data needed for using d3admin, can be provided via command-line options. When adding a package without the --walkthru/-w option, required attributes *must* be provided via options, or an error occurs. Non-required attributes will use default values, or inherit them from the previous [edition](#edition) of the same [basename](#basename).

The command

`d3admin add transmogrifier -g test-macs -e /tmp/test-preinstall`

will add a new package for the basename 'transmogrifier'. It assumes there is a previous [edition](#edition) of transmogrifier, and the new one will have the same [version](#version), and the [revision](#revision) will be incremented by one. The package will [auto-install](#auto-groups) on machines in the computer group 'test-macs' and the script located at /tmp/test-preinstall will be added to Casper and uses as the d3 pre-install script.
All other attributes of the package will be inherited from the previous edition.

If there is no previous edition, the version must be provided with -v, and the revision will be 1. All other attributes will have default values.

`d3admin edit transmogrifier-2.5-2 -G 'special-macs,other-macs' -e 324`

This command will change the [excluded-groups](#excluded-groups) for the package with edition transmogrifier-2.5-2 to 'special-macs' and 'other-macs', and will set the pre-install script to the JSS Script with id 324.

This mode is designed for automated package manipulation, usually as a step at the end of a build process, as from XCode. 

([Top](#table-of-contents))

#### add

Adding packages to d3 is done with 

`d3admin add <basename> <options>`. 

Using the --walkthru/-w  option will present a menu with which you can define all aspects of the package. Without --walkthru, [version](#version), [revision](#revision), and source-path must be provided with --version/-v, --revision/-r, and --souce-path/-s. All other options will use default values if omitted.

The source path is a locally accessible path to one of:

- a .pkg installer, from any source
- a proper Casper .dmg installer, usually from Composer.app
- a 'root' folder representing the root of the target computer where the install will happen.

When given a path to a root folder, d3admin will use it to build a simple .pkg installer, or if --dmg/-D is given, a Casper .dmg installer. In this situation, the --workspace/-W option can be used to provide a path to a "workspace" folder where the .pkg or .dmg is built before uploading to Casper. The workspace folder is remembered between uses of d3admin.


#### edit

Packages in d3 can be edited with 

`d3admin edit <basename or edition> <options>`

Using the --walkthru/-w  option will present a menu with which you can edit all aspects of the package.

Without --walkthru, any options specified on the command line will be changed, others will be untouched.

#### make live

All newly-added packages have the status ['pilot'](#pilot) and must be made ['live'](#live) (released) to be generally available in d3. 

`d3admin live <edition>`

will make the [edition](#edition) live, as long as the edition is currently a pilot.

Doing this will affect the [statuses](#status) of other packages with the same [basename](#basename):

- The package that was previously live will become [deprecated](#deprecated)
- Any pilot packages between the previously live one and this one will become [skipped](#skipped)
- Any newer packages than this one will remain [pilots](#pilot)

#### delete

To delete a package from d3: 

`d3admin delete <basename or edition> <options>`

Options can be used to

- delete the Casper scripts associated with the package (if they aren't used elsewhere)
- leave the package in Casper while deleting it from d3
- archive the d3 package.

##### archiving

When a package is archived its d3 metadata is stored for future reference in a special database table. Optionally, the .pkg or .dmg itself can be saved aside to a special folder on the master distribution point. 

#### package lists

The 'show' command of d3admin will present a list of packages on the server.

`d3admin show` or `d3admin show all`

will show the [edition](#edition) of every package in d3, along with its [status](#status), when and by whom it was added, and when and by whom it was released (made live).

The show command can take 'pilot', 'live', 'deprecated', 'skipped', and 'archived' to show just those packages.

#### reports

d3admin can generate reports about d3 packages installed on clients. It does this by querying the JSS for data about installed Casper package receipts, so the data is only as up-to-date as the most recent recon for each machine.

`d3admin report --type <type> <target>...`

The report types available are:

- pilot: targets are basenames. Lists machines piloting any edition of the basename
- installed: targets are basenames. Lists machines with any edition of the basename installed.
- deprecated: targets are basenames. Lists machines with out-of-date installs of the basename
- computer: targets are computer names. Lists all d3 packages installed on the computer(s)

More detailed info can be obtained by running one of the `d3 list-*` commands on the client machine(s) in question.


## Configuration

### jss_gem.conf

([Top](#table-of-contents))


### d3.conf

([Top](#table-of-contents))


### d3admin and your keychain

([Top](#table-of-contents))

