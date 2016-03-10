# Packages in d3

A package in d3 is a package in Casper. d3 stores extra data about packages, which provide enhancements over standard Casper package handling, such as [automatic updates](#sync), [conditional installs](#conditional-installs), [piloting](#piloting), [expiration](#expiration), and so on.

This page describes the many attributes of d3 packages. For info about installing packages on client computers, see [Installing Packages](Client#installing-packages). For info about adding, editing, and deleting packages in d3, see [d3admin](Admin#d3admin).

A d3 package has all the attributes of a Casper package, plus those listed here. While it's possible to edit the Casper attributes via Casper Admin or the JSS web UI, we recommend using [d3admin](#d3admin) for all work with d3 packages, since d3admin will help enforce d3-specific data-integrity. 

## status
As a package spends time in d3, its status will change.

##### pilot

Packages that are newer in d3 than the currently [live](#live) package for their [basename](home#basename) have the status 'pilot'.

All packages are pilots when first added to d3. Pilot packages can be manually installed on clients using the [`d3 install`](Client#piloting) command with the package's [edition](home#edition). 

Once installed, the pilot package's [basename](home#basename) is skipped during a [`d3 sync`](Client#syncing) so it won't get any automatic updates if another edition is made live. 

##### live

Once a package has been [piloted](Client#piloting) and is ready for general deployment, it is released by [changing it's status to 'live'](Admin#make-live).
  
There can only be one live package per [basename](home#basename) at a time, and using a basename to refer to a package will always yield the currently live one (if any).

When a package is made live...

  * It becomes default for its basename.
    
    It's the package installed with [`d3 install <basename>`](Client#installing-packages).
    
  * It automatically installs on scoped computers.
    
    At the next [`d3 sync`](Client#syncing), it will be installed if the computer is a member of any of the package's [auto-install groups](#auto-groups).
    
  * It automatically updates any older [editions](home#edition). 

    At the next [`d3 sync`](Client#syncing), if an older edition is installed, and not a pilot, the new live one is installed.
  

##### deprecated

A package that was once live, but has been superceded by a newer edition of it's  basename, becomes 'deprecated'.  Deprecated packages stay on the server until deleted either manually with [`d3admin delete`](Admin#delete) or with [auto-cleaning](Admin#auto-cleaning)

##### skipped

A package that is older than the currently live one for its basename, but was never  made live itself is 'skipped'. Skipped packages stay on the server until deleted either manually with [`d3admin delete`](Admin#delete) or with [auto-cleaning](Admin#auto-cleaning)



## Package properties

### Description

This is a textual description of the package and what it installs. 

Descriptions are important when you start to have many packages and many d3 admins. A good description not only says what is installed, but also includes urls or developer info and anything else to help an unfamiliar admin known what the packge is for.

The description is stored in the "Notes" field of the Casper package settings.

### Auto groups

These are Casper computer groups (static or smart) whose members will have the package automatically installed at the next [`d3 sync`](Client#syncing). 

##### Standard auto-installs

There is a special, pseudo-group-name used for auto-grouping called 'standard'. When a package has the auto-group 'standard' it is auto-installed on _all_ d3 client computers.

### Excluded groups

One or more Casper computer groups (static or smart) whose members are normally prohibitied from installing the package 

A computer in one of the package's excluded groups won't even see the package in the  [list of available packages](Client#getting-info-about-packages) 

If [force](Client#force) is used, the package can be listed and installed.

### Pre- and Post- scripts

While .pkg installers might have internal pre- and post- install scripts, .dmg installers do not.  Also, while Casper policies can run Casper scripts before and after package (un)installation, the process can't easily be stopped if the pre- script fails.

d3 provides pre- and post-install, and pre- and post-remove scripts. These scripts are just Casper scripts, and under the hood, they are run via the `jamf runScript` command.

When a d3 pre-install script runs, its exit status must be 0 (zero - success) or else the package won't be installed.

Similiarly when a d3 pre-remove script runs, if its exit status is not zero, it won't be uninstalled.

#### Exit status 111 on pre- scripts
Both pre-install and pre-remove scripts cause special behaviour when their exist status is 111:

* If the pre-install script exits 111, the package will NOT be installed, but the d3 [receipt](Receipts) will be written as if it were.

  A possible use-case for this is the CrashPlan client. Crashplan has its own client-update mechanism that happens from it's own servers.
  
  If some version of CrashPlan is initially installed via d3, the pre-install script for the next version might check to see if Crashplan has already been updated by its own server, and in that case, it exits 111. d3 the writes its receipt so that it knowns things are up-to-date. On machines that don't have crashplan installed at all, the script can do whatever pre-install actions needed  (such as putting customization files in place) and then exit 0 to allow a normal install to happen.

* If the pre-remove script exits 111, the `jamf uninstall` will not be run, but the d3 receipt will be removed.

  A use-case here is an application for which  there's an 'uninstaller' app or pkg.
  
  A regular d3/jamf uninstall will just remove the files that were originally installed, but the uninstaller provided by the app's developer might remove many other things, or do so in a way that doesn't break other products.
  
  In this case, the pre-remove script can just run the developers uninstaller, and then exit 111, which causes d3 to remove its receipt and do no more.


### Prohibiting process

Packages can be configured with the name of a process which, if running at install time, prevents installation.

The process name is compared to the output of `/bin/ps -A -c -o comm` and if it matches a line of that output, the package isn't installed.


### Remove first

If this attribute is true, then before installing the package, any previously installed version of the same basename is [uninstalled](Client#uninstalling) first. 

### Uninstallable

Some packages should never be [uninstalled](Client#uninstalling), or serious problems will occur. Examples include: OS updates, security updates, and any Apple package that affects core frameworks of the OS. When this attribute is false, the package can never be uninstalled by d3.


### Reboot (PuppyTime!)

This is the 'requires restart' setting for the Casper package. 

However, when installed with [`d3 install`](Client#installing-packages) the package is not installed immediately, (unless the -p option is used). Instead, a reference to the package is added to the ['puppy queue'](Client#puppytime) and the user might [be notified](Configuration#policies-and-scripts-used-by-d3) to log out. 

### OS limitations

This is the casper 'os limitations' setting. It is enhanced by the JSS module's ability to understand "minimum OS" in the format ">=10.9.5", which it expands into a very long list of future OS versions. 


### Expiration

Expiration is d3's ability to automatically uninstall packages that haven't been used in some time. When an installed package expires, it is automatically uninstalled during a [sync](Client#syncing).

For details about how expiration happens, see [here](Client#expiration)

Packages have two attributes related to expiration:

* expiration

  This is an integer representing the number of days of disuse required before a package is expired. For example, if the expiration is 30, the package will be removed after 30 days of disuse. Setting the expiration to zero (the default) means the package never expires.

* expiration_path

  This is the path to the executable that must come to the foreground to be counted as "use"

  For example, a package that installs /Applications/Foobar.app, might have  expiration_path of /Applications/Foobar.app/Contents/MacOS/Foobar

