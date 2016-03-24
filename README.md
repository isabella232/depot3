# d3 - Command line package and patch management for Casper

d3 is a package deployment and patch management system for OS X that enhances the
[Casper Suite](http://www.jamfsoftware.com/products/casper-suite/), an enterprise-level management system for Apple devices from [JAMF Software](http://www.jamfsoftware.com/). It was created by [Pixar Animation Studios](http://www.pixar.com/).

d3 adds these, capabilities and more, to Casper's package handling:

* Automatic software updates on clients when new versions are released on the server
* Pre-release piloting of new packages
* Customizable slideshow presented during logout/reboot installs
* Installs and uninstalls are conditional on the exit status of pre-flight scripts
* Packages can be expired (auto-uninstalled) after a period of disuse
* Both the client and admin tools are command-line only and fully scriptable
* Admin command-line options allow integration with developer workflows and package-retrieval tools

d3 is written in Ruby and available as a rubygem called ['depot3'](https://rubygems.org/gems/depot3). It interfaces with Casper mostly via it's REST API using [ruby-jss](https://github.com/PixarAnimationStudios/ruby-jss), a ruby module that provides simple and powerful access to the API. It also uses Casper's backend MySQL database directly to provide enhanced features.

## Documentation

The main documentation is in the [GitHub wiki](https://github.com/PixarAnimationStudios/depot3/wiki).

The developer documentation for the D3 ruby module is at [http://www.rubydoc.info/gems/depot3](http://www.rubydoc.info/gems/depot3)

Also check out [ruby-jss](https://github.com/PixarAnimationStudios/ruby-jss), which is used by d3, but is useful for working with the Casper REST API in any project. 


## COMPONENTS

d3 is made of several parts.

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
  to write additional tools that interact with d3. See [http://www.rubydoc.info/gems/depot3](http://www.rubydoc.info/gems/depot3) for the module documentation.



## EXAMPLES

Check out some [basic vocabulary](http://pixaranimationstudios.github.io/depot3/index.html#basic-vocabulary) for learning how d3 uses words like 'sync', 'live', 'edition' and so on.

### d3

* Install the currently live edition of a package

  `sudo d3 install transmogrifier`

* Install an un-released edition for piloting

  `sudo d3 install transmogrifier-15-2`

* List currently installed packages

  `sudo d3 list-installed`

  Most d3 actions have short versions, such as 'li' for 'list-installed',
  and 'i' for 'install'

* Perform all automated tasks

  `sudo d3 sync`

  Syncing is usually done at regular intervals by a launchd job or Casper policy.
  However it can be run manually at any time to get a client immediately
  up-to-date. The sync command performs these tasks:
  
  * Update the local receipts with any relevant changes from the server packages
  * Auto-install new packages that are in-scope
  * Auto-update any installed packages if an update has been made live
  * Expire any packages that haven't been brought to the foreground within the
    expiration period.

### d3admin

* Add a new package to d3 interactively

  `d3admin add transmogrifier --walkthru`

  This will present a menu of options for defining the new package. If a previous
  edition is already in d3, it will be used for the default values of the new one.


```
------------------------------------
Adding pilot d3 package 'transmogrifier-20-7'
with values inherited from 'transmogrifier-20-6'
------------------------------------
1) Basename: transmogrifier
2) Version: 20
3) Revision: 7
4) JSS Package Name: transmogrifier-20-7.pkg
5) Description:
----
This is a descriptive description
it describes this package in great depth.
----
6) Dist. Point Filename: transmogrifier-20-7.pkg
7) Category: testing
8) Limited to OS's: 10.10.x
9) Limited to CPU type: none
10) Needs Reboot: false
11) Uninstallable: true
12) Uninstalls older installs: true
13) Installation prohibited by processes matching: Safari
14) Auto installed for groups: standard
15) Not installed for groups: byod
16) Pre-install script: transmogrifier-foo
17) Post-install script: transmogrifier-foo
18) Pre-uninstall script: transmogrifier-foo
19) Post-uninstall script: transmogrifier-foo
20) Expration: 30
21) Expration Path: /Applications/Transmogrifier.app/Contents/MacOS/transmogrifier
22) Source path: /Users/Shared/Transmogrifier.pkg
Which to change? (1-22, 'x' = done):
```

* Add a new package to d3 with command-line options (split to multi-line for clarity)

  Not all options need to be provided. Those not provided will either inherit from
  the previous edition or use default values.


```
d3admin add transmogrifier \
  --source-path /Users/Shared/Transmogrifier.pkg \
  --description 'this is a new description' \
  --pre-install 'better pre-install script' \
  --auto-groups standard \
  --excl-groups special-macs \
  --oses '>=10.10.1' \
  --remove-first \
  --category test-apps \
  --expiration 30 \
  --expiration-path /Applications/Transmogrifier.app/Contents/MacOS/transmogrifier
```

* Make a package live

  `d3admin live transmogrifier-20-7`

  Once live, the package will install automatically when a client
  runs `d3 sync` if:
  
  * An older edition of the same basename is installed (auto updating)
  * The client is in one of the "auto-install" computer groups listed for the package. (scoped auto-installs)


* Edit the settings of an existing package interactively

  `d3admin edit transmogrifier-20-7 -w`

  This creates a menu similar to the above. -w is the short version of --walkthru. 
  
  Edits can be made non-interactively by providing all new values on the commandline.

As with d3, all actions and options for d3admin have short versions.


## INSTALLATION & SETUP

See [Installing and configuring d3](https://github.com/PixarAnimationStudios/depot3/wiki/setup)

## KNOWN LIMITATIONS

D3 was created to meet our needs in our environment. As such it might not be appropriate for all Casper users. However, by making it open-source, we hope that others will be able to expand it's capabilities to work in a wider variety of situations.

That said, here are a few things we know regarding its limitations in other environments:

* d3 talks directly to the JSS MySQL database. It must in order to provide the enhancements to Casper.
* d3 can't be used with Cloud-instances of the JSS, due to then need for MySQL access
* File-share distribution points are assumed. Especially the Master Distribution Point. However, if your JSS has a Cloud Distribution Point Defined, d3 will attempt to use it if the FileShare Dist point isn't available. We've only tested this with AWS.
* D3 doesn't automatically find or retrieve updates/patches from the 'net.  Other tools exist to do that, and we may look into integrating AutoPkg, or something similar, eventually.

## CONTACT

[Email the developer](mailto:d3@pixar.com)

[Macadmins Slack Channel](https://macadmins.slack.com/messages/#d3/)

## LICENSE

Copyright 2016 Pixar

Licensed under the Apache License, Version 2.0 (the "Apache License")
with the following modification; you may not use d3 except in
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
