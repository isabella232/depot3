# d3 Client

([Table of contents](TOC#table-of-contents))

A d3 client is a computer managed by Casper, that uses d3 to do local package management, as well as the command-line utility used to do it. 

## d3 command-line utility

The `d3` command is the heart of d3 and us used for [piloting](#piloting), [installing](#installing), [uninstalling](#uninstalling), [syncing](#sync), and generating various lists and info. Use `d3 help` to see the help screen. Most use of d3 must be done as root. 

The general form of a d3 commandline is `d3 [options] command [argument [...]]`

- A command is always required, and tells d3 what you want to do, e.g. 'install', 'sync', 'list-available', and so on.
- The argument(s) are thing or things you want to perform the command with
- The options can change the behavior of the command, or provide extra info.

For detailed documentation of all commands and options, see [TODO: add this link](d3-man-page)


## receipts

d3 keeps track of what's installed by maintaining a set of receipts on the local disk. These receipts are separate from the JSS package receipts, and also different from the Apple package receipt system available via `pkgutil`. A d3 receipt stores all info needed to work with the package after installation. 


## installing packages

d3 has two commands that install packages: install and pilot.

Most normal installation is done with the install command: `d3 install basename`.

This causes the currently [live](#status) package for the basename to be installed. More than one basename can be provided, all will be installed.

During installation, d3 will first check that no [prohibiting process](#prohibiting-process) is running, and then will uninstall older versions of its basename if the remove-first attribute is true. Then d3 will run any [pre-install script](#pre-and-post-scripts). If the script exits successfully, the package is installed using `jamf install` and if the install was successful, any [post-install script](#pre-and-post-scripts) is run.

In order to install, d3 needs to know the name of a non-root 'admin' who is doing the install. If d3 can't figure out a name on it's own, it must be provided with the -a/--admin option.  

### piloting

In order to test packages before they are made live, install them with the 'pilot' command: `d3 pilot edition` 

d3 will then install the [pilot](#status) package indicated by the [edition](#edition) as described above. 

However! Once a package is in pilot, the [sync](#sync) process will stop auto-updating that basename. The only exception to this is when the edition being piloted becomes live, in which case the receipt for the pacakge is modified to reflect that, and the package is no longer in pilot.

If a package is in pilot on some machine, and some other, newer package becomes live, that machine will _never_ get any new version of the basename until someone uninstalls the pilot with `d3 depilot edition`. 

It is ultimately the responsibility of the admin doing the piloting to ensure clients are depiloted as needed. To help with this, [d3admin](#d3admin) can generate reports of clients that are piloting packages.

### conditional installs

See [pre- and post- scripts](#pre-and-post-scripts) for a discussion of conditional installs and uninstalls, as well as the special meaning of scripts exiting with status 111.


### uninstalling

If a package is marked as removable, then `d3 uninstall basename` will uninstall it.  To uninstall pilots, you must use `d3 depilot basename`


## sync

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


## scoping

d3 itself provides basic scoping via the [auto-groups](#auto-groups) and [excluded-groups](#excluded-groups). This can handle most of the scoping needs for most packages. 

If more complex scoping is needed, one method is to assign no auto- or excluded-groups, and use a fully-scoped Casper policy to perform the ['d3 install'](#installing) command.


## force

The --force/-f option to d3 causes it to do many things that it wouldn't normally do. 

For example, if a package is excluded for one of the machine's groups, it can still be installed or piloted with --force. 

Excluded packages normally don't show up in the list of available packages, but --force will cause all packages to be listed.



## d3RepoMan

d3RepoMan is a background process that locally records a timestamp every time an application comes to the foreground in the machine's UI. It is required to use d3's [expiration]#(expiration) feature, and it allows the use of that feature without turning on Casper's 'application usage logging', which stores that data on the server. 

The process is launched by a machine-wide Launch Agent, and runs as the user logged in. It writes a different plist for each user in the directory /Library/Application Support/d3/Usage.  Those plists are used by the [sync](#sync) process as it performs expirations. 


## puppytime

Some packages require a reboot after they are installed. d3 handles these using a system called 'puppytime' - a name inherited from a tool used by Pixar to automate such installations long before d3 was written. The original tool would display a slide-show of cute puppy images while the installation(s) were happening, after logout and before reboot.

When d3 'installs' a package requiring reboot, info about the package is added to the 'puppy queue' and a Casper policy of your choice is executed. The policy should somehow notify the user to log out as soon as possible to perform the installs. 

At logout, a process runs which examines the queue, and installs all the packages there, while displaying a slideshow of images. 

The default images that come with d3 are still puppies, however they can be customized easily. 



### puppy queue

The contents of the puppy queue can be listed with with `d3 list-queue` and items therein can be removed with `d3 dequeue basename`

## casper policies and scripts used by d3

Several things in d3 can be customised by way of Casper policies. 

- Packages added to the puppy queue: a policy is triggered to handle notification and any other tasks desired.





### environment variables

([Table of contents](TOC#table-of-contents))


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
