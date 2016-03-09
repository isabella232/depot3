# Introduction to d3

([Table of contents](TOC#table-of-contents))

## What is d3?

d3 is a package deployment and patch management system for OS X that enhances the 
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

## History

Many years ago, Pixar's original NFS-based software deployment system for Unix workstations was called "depot". When it had outgrown itself, a replacement based on RPM packages was created and called "depot2", or "d2" for short. When Mac OS X arrived at Pixar in 2002, the Mac team adopted many of the Linux team's existing tools, including d2. 

By 2008 the original developer of d2 had left, and d2's applicability and sustainability for the Macs (never great to start with) was waning. Also, the world of Mac Sys Admins was changing to become what it is today. In 2009 the Pixar Mac team starting looking at third-party tools that might replace d2.  

Nothing seemed to be an exact fit for our needs, but the Casper Suite from JAMF Software seemed promising, and offered other tools very similar to our own home-grown Mac infrastructure. We realized that with a little customization, Casper could provide the features we wanted.  The first version of d3 was created in 2010 to add those features. 

The second version of d3, which utilised the newly-released Casper REST API, was presented at the 2012 JAMF Nation User Conference in Minneapolis. One of the first questions from the audience was "Is it open-sourced?", to which we had to say no. 

Since then, work has been progressing on the third version of d3 with a goal of enhancing its features and refactoring the code-base for eventual open-source release. The first step towards that goal was the 2014 release of the JSS ruby module, which provides comprehensive access to the Casper REST API, and upon which d3 is built. D3 itself took another 18 months before the first upload to github.

## Basic Vocabulary

The following terms are fundamental to understanding any discussion of d3.

### basename

A basename in d3 is a word used to identify all packages that install any version of the same thing. For example "transmogrifier" could refer to all packages in d3 that install any version of Transmogrifier.app. When a basename alone is used to specify a package, it always refers to the currently [live](#pilot--live) package for the basename. 

### pilot & live

When packages are added to d3, they are "in pilot" and their status is 'pilot'. This means they are yet approved for general deployment, but can be installed for testing using their edition (see below). When a pilot is installed on a computer, it won't be [automatically updated](#sync)  unless that exact package becomes 'live'

After testing, the package can be [made live](#make-live), i.e. released. Only one package in a basename can be live at a time. This makes it available for installation by their basename alone.[Syncing a client](#sync) will auto-install the live package if appropriate, and update any previously installed package for the same basename.

See also: [status](#status), [installing](#installing), [piloting](#piloting), [admin](#admin) 

### version

This is the version of the thing installed by a package. A package that installs Transmogrifier might install version 2.1.2, while another package that installs Transmogrifier might install version 2.2.3. Versions can include any alpha-numeric characters, e.g. "12.5a3"


### revision

This is a number representing how many times some version of a basename has been added to d3. When Transmogrifier 2.2.3 is added to d3 for the first time, it's revision will be 1.  Later, a problem may be discovered with the .pkg itself, and a new .pkg for version 2.2.3 might be created. When added to d3, it will have the revision 2.

### edition

The edition is a combination of basename, version, and revision of a package, joined by hyphens. It is a unique identifier for each package in d3.

For example, there might be three editions of the basename 'transmogrifier' in d3 at the same time:  transmogrifier-2.1.2-1, transmogrifier-2.1.2-2, and transmogrifier-2.2.3-1. When specifying any package that isn't [live](#live), the edition is used to identify it.

Only one edition of a basename can be installed at a time.

See also: [status](#status)

([Table of contents](TOC#table-of-contents))