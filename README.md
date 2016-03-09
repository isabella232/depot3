# D3 - Command line package and patch management for Casper

D3 is a package deployment and patch management system for OS X that enhances the
Casper Suite from [JAMF Software LLC](http://www.jamfsoftware.com/products/casper-suite/). It was created by Pixar Animation Studios.

D3 adds these capabilities to Casper's package handling:

* Automatic software updates on clients when new versions are released on the server
* Pre-release piloting of new packages
* Customizable slideshow presented during logout/reboot installs
* Installs and uninstalls are conditional on the exit status of pre-flight scripts
* Packages can be expired (auto-uninstalled) after a period of disuse
* Both the client and admin tools are command-line only and fully scriptable
* Admin command-line options allow integration with developer workflows and package-retrieval tools

D3 is written in Ruby and available as a Ruby gem called 'depot3'. It interfaces with
Casper mostly via it's REST API using the [JSS Ruby module, available via the
'jss-api' gem](https://github.com/PixarAnimationStudios/jss-api-gem). It also accesses the JSS's backend MySQL database directly to provide enhanced features.

## Documentation

See the full d3 [administrator documentation](docs/TOC.md)  and the [developer documentation](http://www.rubydoc.info/gems/depot3)


## COMPONENTS

D3 is made of several parts.

* d3 - the client.

  The d3 command is the heart of the system. It provides:
  * Pre-release piloting of new packages
  * Manual package installation, uninstallation
  * Queuing of packages requiring reboot
  * Removal or installation of packages in the logout/reboot queue
  * Automatic scoped installations
  * Automatic updates
  * Automatic expiration of unused packages
  * Various kinds of reporting (packages available, packages installed, packages being piloted, etc)

* d3admin - the package administration tool.

  The d3admin command allows administrators and developers to:
  * Add packages to d3 for piloting
  * Release pilot packages for deployment (i.e. 'make them live')
  * Edit package attributes and settings
  * Delete or archive packages
  * View reports about package installations
  * Interactively prompt for all options or...
  * Accept all options from the commandline, for integration with development workflows.

* puppytime - installation of the logout-install queue

  Puppytime handles the installation of packages in the logout queue. It is
  triggered by a Casper logout policy, and displays a slideshow to the user
  while the installs are happening. After installation, the machine reboots
  in a customizable manner.
  The default images are a selection of cute puppies, but any images can be used.

* d3helper - miscellaneous functionality.

  Currently d3helper provides a method to display a notification to users that
  something has been added to the logout queue, and they should log out soon.
  Any other notification method can be used instead, as the notification is
  handled by a Casper policy.
  d3helper may provide other uses in the future.

* d3RepoMan.app

  This background process is needed if you opt to use the expiration feature of d3.
  It registers with the OS for low-level notifications and simply records a
  timestamp in a plist every time any app comes to the foreground in the GUI.
  When 'd3 sync' is running, installed packages that are expirable are checked
  agains the plists to see if they've been in the foreground recently enough, and if not,
  they are uninstalled.


* The D3 ruby module

  The core funtionality of d3 is in the D3 module, which makes it straightforward
  to write additional tools that interact with d3. See [here](http://some/url)
  for the module documentation.

* Editions

  Perhaps *the* core concept in d3 is the "edition". Each package in d3 has a unique
  combination of 'basename', 'version' and 'revision' which together
  create the edition.
  * Basename - this name is what links different packages together as installing
  different versions of the same software. For example 'filemaker' might be the
  basename for all pacakges that install FileMaker Pro.
  * Version - this is the actual version of the thing being installed, for example
  "1.2"
  * Revision - this is an integer representing a sequential packaging of the same
  version of something. If you build a package for version '2.5' of basename 'foo'
  it will start at revision 1 If you later realize the package itself is malformed,
  and rebuild it, the new package still installs version 2.5, but is now revision 2
  * Edition - a unique identifier for a package in d3, made by joining the
  basename-version-revision with hyphens, for example "filemaker-13.0-1" or 'foo-2.5-2'
  Editions are used when you need to specify an exact package, such as when installing
  a pilot. Basenames are usually used to work with the currently live edition of that
  basename.


## EXAMPLES

### d3

* Install the currently live version of a package

  `sudo d3 install filemaker`

* Install an un-released version for piloting

  `sudo d3 pilot filemaker-15-2`

  Once a package is installed as a pilot, it is no longer checked for updates
  during a sync. It is the admin's responsibility to remove the pilot install
  when testing is complete. The only exception is when the same edition
  becomes live, the status of the local install is changed from pilot to live.

* List currently installed packages

  `d3 list-installed`

  Most d3 commands have short versions, such as 'li' for 'list-installed',
  and 'i' for 'install'

* Perform all automated tasks

  `sudo d3 sync`

  Syncing is usually done at regular intervals by a launchd job or Casper policy.
  However it can be run manually at any time to get a client immediately
  up-to-date. The sync command performs these tasks:
  * If any pilot installs have become live, mark them so.
  * Auto-install new packages that are in-scope
  * Auto-update any installed non-pilot packages if an update has been released
  * Update the local receipts with any relevant changes from the server packages
  * Expire any packages that haven't been brought to the foreground within the
    expiration period.

### d3admin

* Add a new package to d3 interactively

  `d3admin add --walkthru --basename 'filemaker'`

  This will present a menu of options for defining the new package. If a previous
  edition is already in d3, it will be used for the default values of the new one.



```
------------------------------------
Adding pilot d3 package 'chrisltest-20-7'
with values inherited from 'chrisltest-20-6'
------------------------------------
1) Basename: chrisltest
2) Version: 20
3) Revision: 7
4) JSS Package Name: chrisltest-20-7.pkg
5) Description:
----
This is a descriptive description
it describes this package in great depth.
----
6) Dist. Point Filename: chrisltest-20-7.pkg
7) Category: testing
8) Limited to OS's: 10.10.x
9) Limited to CPU type: none
10) Needs Reboot: false
11) Uninstallable: true
12) Uninstalls older installs: true
13) Installation prohibited by processes matching: Safari
14) Auto installed for groups: standard
15) Not installed for groups: byod
16) Pre-install script: chrisltest-foo
17) Post-install script: chrisltest-foo
18) Pre-uninstall script: chrisltest-foo
19) Post-uninstall script: chrisltest-foo
20) Expration: 3
21) Expration Path: /Applications/Foobar.app/Contents/MacOS/Foobar
22) Source path: ---Required---
Which to change? (1-22, 'x' = done):
```

* Add a new package to d3 with command-line options (split to multi-line for clarity)

  Not all options need to be provided. Those not provided will either inherit from
  the previous edition or use default values.


```
d3admin add --basename chrisltest \
  --description 'this is a new description' \
  --pre-install 'better pre-install script' \
  --auto-groups standard \
  --excl-groups special-macs \
  --oses '>=10.10.1' \
  --remove-first \
  --category test-apps \
  --expiration 30 \
  --expiration-path = /Applications/Test.app/Contents/MacOS/test
```

* Make a package live

  `d3admin live --edition chrisltest-20-7`

  Once live, the package will install automatically when a client
  runs `d3 sync` if:
  * An older, non-pilot, edition of the same basename is installed (auto updating)
  * The client is in one of the "auto-install" computer groups listed for the package. (Scoped auto-installs)


* Edit the settings of an existing package interactively

  `d3admin edit --walkthru --edition chrisltest-20-7`

  This creates a menu similar to the above. Edits can be made non-interactively by
  providing all new values on the commandline.

As with d3, all commands and command-line options for d3admin have short versions.


## INSTALLATION & SETUP

At the moment there is no automated installation. Eventually there will be (when I learn rake)

Using d3 will require these steps:

1. Creating (if needed) read-only and read-write users for the Casper REST API
2. Creating (if needed) read-only and read-write users for the MySQL database
4. Creating the /etc/jss_gem.conf and /etc/d3.conf files
1. Installing d3 on an admin Mac with `(sudo) gem install depot3`
3. Creating the d3_packages and d3_archive tables in the MySQL database
4. Adding or importing packages into d3 with d3admin
5. Creating a launchd plist or Casper policy to run regular d3 syncs on clients
6. Create a policy to do puppytime notifications
7. Create other optional policies and scripts
5. Creating a package & policy to install d3 onto clients
6. Giving access to other d3 administrators as needed




## KNOWN LIMITATIONS

D3 was created to meet our needs in our environment. As such it might not be appropriate for all Casper users. However, by making it open-source, we hope that others will be able to expand it's capabilities to work in a wider variety of situations.

That said, here are a few things we know regarding its limitations in other environments:

* File-share distribution points are assumed. Especially the Master Distribution Point. However, if your JSS has a Cloud Distribution Point Defined, d3 will attempt to use it if the FileShare Dist point isn't available. We've only tested this with AWS.
* D3 doesn't automatically find or retrieve updates/patches from the 'net.  Other tools exist to do that, and we may look into integrating AutoPkg, or something similar, eventually.


## HISTORY

Many years ago, Pixar's original NFS-based software deployment system for Unix workstations was called "depot". When it had outgrown itself, a replacement based on RPM packages was created and called "depot2", or "d2" for short. When Mac OS X arrived at Pixar in 2002, the Mac team adopted many of the Linux team's existing tools, including d2.

By 2008 the original developer of d2 had left, and d2's applicability and sustainability for the Macs (never great to start with) was waning. Also, the world of Mac Sys Admins was changing to become what it is today. In 2009 the Pixar Mac team starting looking at third-party tools that might replace d2.

Nothing seemed to be an exact fit for our needs, but the Casper Suite from JAMF Software seemed promising, and offered other tools very similar to our own home-grown Mac infrastructure. We realized that with a little customization, Casper could provide the features we wanted.  The first version of d3 was created in 2010 to add those features.

The second version of d3, which utilised the newly-released Casper REST API, was presented at the 2012 JAMF Nation User Conference in Minneapolis. One of the first questions from the audience was "Is it open-sourced?", to which we had to say no.

Since then, work has been progressing on the third version of d3 with a goal of enhancing its features and refactoring the code-base for eventual open-source release. The first step towards that goal was the 2014 release of the JSS ruby module, which provides comprehensive access to the Casper REST API, and upon which d3 is built. D3 itself took another 18 months before the first upload to github.

## HELP

[Email the developer](mailto:d3@pixar.com)

[Macadmins Slack Channel](https://macadmins.slack.com/messages/#d3/)

## LICENSE

Copyright 2016 Pixar

Licensed under the Apache License, Version 2.0 (the "Apache License")
with the following modification; you may not use this file except in
compliance with the Apache License and the following modification to it:

Section 6. Trademarks. is deleted and replaced with:

  6\. Trademarks. This License does not grant permission to use the trade
  names, trademarks, service marks, or product names of the Licensor
  and its affiliates, except as required to comply with Section 4(c) of
  the License and to reproduce the content of the NOTICE file.

You may obtain a copy of the Apache License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the Apache License with the above modification is
distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied. See the Apache License for the specific
language governing permissions and limitations under the Apache License.
