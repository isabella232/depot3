## What is d3?

d3 is a package deployment and patch management system for OS X that enhances the 
Casper Suite from [JAMF Software LLC](http://www.jamfsoftware.com/). It was created by Pixar Animation Studios.

d3 adds these capabilities and more to Casper's package handling:

* Automatic software updates on clients when new versions are released on the server
* Pre-release piloting of new packages
* Customizable slideshow presented during logout/reboot installs
* Installs and uninstalls are conditional on the exit status of pre-flight scripts
* Packages can be expired (auto-uninstalled) after a period of disuse
* Both the client and admin tools are command-line only and fully scriptable
* Admin command-line options allow integration with developer workflows and package-retrieval tools

d3 is written in Ruby and available as a [github project](https://github.com/PixarAnimationStudios/depot3) and a [Ruby gem](https://rubygems.org/gems/depot3/) called 'depot3'. It interfaces with Casper mostly via it's REST API using the [JSS Ruby module](https://github.com/PixarAnimationStudios/ruby-jss). It also accesses the JSS's backend MySQL database directly to provide enhanced features.

## History

Many years ago, Pixar's original NFS-based software deployment system for Unix workstations was called "depot". When it had outgrown itself, a replacement based on RPM packages was created and called "depot2", or "d2" for short. When Mac OS X arrived at Pixar in 2002, the Mac team adopted many of the Linux team's existing tools, including d2. 

By 2008 the original developer of d2 had left, and d2's applicability and sustainability for the Macs (never great to start with) was waning. Also, the world of Mac Sys Admins was changing to become what it is today. In 2009 the Pixar Mac team starting looking at third-party tools that might replace d2.  

Nothing seemed to be an exact fit for our needs, but the Casper Suite from JAMF Software seemed promising, and offered other tools very similar to our own home-grown Mac infrastructure. We realized that with a little customization, Casper could provide the features we wanted.  The first version of d3 was created in 2010 to add those features. 

The second version of d3, which utilised the newly-released Casper REST API, was presented at the 2012 JAMF Nation User Conference in Minneapolis. One of the first questions from the audience was "Is it open-sourced?", to which we had to say no. 

Since then, work has been progressing on the third version of d3 with a goal of enhancing its features and refactoring the code-base for eventual open-source release. The first step towards that goal was the 2014 release of the JSS ruby module, which provides comprehensive access to the Casper REST API, and upon which d3 is built. D3 itself took another 18 months before the first upload to github.

## Basic Vocabulary

The following terms are fundamental to understanding any discussion of d3.

### Basename

A basename in d3 is a word used to identify all packages that install any version of the same thing. Every package has a basename, and will share it with other packages that install the same thing. For example "transmogrifier" could refer to all packages in d3 that install any version of Transmogrifier.app. 

When a basename alone is used to specify a package, it always refers to the currently [live](#pilot--live) package for the basename. 


### Version

Every package also has a version, which is the version of the thing installed by the package. A package that installs Transmogrifier might install version 2.1.2, while another package that installs Transmogrifier might install version 2.2.3. Versions can include any alpha-numeric characters, e.g. "12.5a3", but they can't include spaces, which will be converted to underscores.


### Revision

A package's revision is an integer representing how many times a single version of a basename has been added to d3. 

When Transmogrifier 2.2.3 is added to d3 for the first time, it's revision will be 1.  Later, a problem may be discovered with the .pkg itself, and a new .pkg for version 2.2.3 might be created. When added to d3, the fixed .pkg will have revision 2.

### Edition

The edition is a combination of basename, version, and revision of a package, joined by hyphens. It is a unique identifier for each package in d3.

For example, there might be three editions of the basename 'transmogrifier' in d3 at the same time:  transmogrifier-2.1.2-1, transmogrifier-2.1.2-2, and transmogrifier-2.2.3-1. When specifying any package that isn't [live](#live), the edition is used to identify it.

Only one edition of a basename can be installed at a time.

### Package

A package in d3 is a package in Casper. It can be used as any other package in Casper, in policies and Casper Remote. When a package is added to d3 (possibly by importing from an existing Casper package), extra data is stored about it, which allows for d3's enhanced features. 

### Receipt

A receipt is the on-disk representation of a d3 Package installed onto a client computer. Receipts have basenames, editions, and status, just like packages. Only one receipt per basename can be installed at a time. d3 receipts are stored separately from JAMF receipts and Apple .pkg receipts.

### Status

As a package spends time in d3, its status will change. Here are the statuses and a brief description of each. For details about the signifigance of each status, see the full discussion of [Packages](packages) and [Receipts](receipts).

##### pilot

When a package is first added to d3, it's considered to be 'in pilot'. Pilot packages are not yet approved for general deployment, but can be manually installed (i.e. '[piloted](packages#piloting)') on individual machines for testing purposes.

##### live

Once a package has been [piloted](#piloting) and is ready for general deployment, it is released by making it 'live'.
  
There can only be one live package per [basename](#basename) at a time, and using a basename to refer to a package will always yield the currently live one (if any). 

##### deprecated

A package that was once live, but has been superceded by a newer edition of it's basename being made live.

##### skipped

A package that is older than the currently live one for its basename, but was never made live itself. 
  
##### missing

A package that is still listed in d3, but has been removed from Casper.  Or, a [receipt](receipts) on a client computer where the matching package on the server has been removed from d3, or is marked as missing.