# d3 Administration
([Table of contents](TOC#table-of-contents))

## d3admin utility

d3admin is a command-line tool for working with d3 packages on the server. Admins who maintain d3 packages will use it to add, edit, and delete packages, as well as make them live and get reports about them.

d3admin cannot be run as root, since it needs to know who's doing things to the packages on the server.

The first time you run d3admin, it will ask you for host and authentication info for the JSS API, the JSS's MySQL server, and the read-write password for the Master Distribution Point. It will store this data in your keychain, so you won't need to enter it every time you use d3admin. If you ever need to update this data, just use `d3admin --config`. See also: [configuration](#configuration)

The general command-line format for d3admin is `d3admin action target(s) [options]` There are two modes for using d3admin: walkthru and command-line. 

### walkthru

When the --walkthru/-w option is is given, d3admin will prompt for a [basename](#basename), [edition](#edition) or other data as needed. If using walkthru for adding or editing a package, it will present a menu of choices for setting the attributes of the package, warning you if invalid data is given. When you're ready to save your changes, you'll be asked for confirmation.

For example `d3admin add -w transmogrifier` will present a menu of choices for adding a new [pilot](#status) package to d3 with the [basename](#basename) 'transmogrifier'. `d3admin edit -w` will prompt for a [basename](#basename) or [edition](#edition) before displaying the menu.

This mode is the easiest to use when manually adding or editing packages.

### command-line

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

### add

Adding packages to d3 is done with 

`d3admin add <basename> <options>`. 

Using the --walkthru/-w  option will present a menu with which you can define all aspects of the package. Without --walkthru, [version](#version), [revision](#revision), and source-path must be provided with --version/-v, --revision/-r, and --souce-path/-s. All other options will use default values if omitted.

The source path is a locally accessible path to one of:

- a .pkg installer, from any source
- a proper Casper .dmg installer, usually from Composer.app
- a 'root' folder representing the root of the target computer where the install will happen.

When given a path to a root folder, d3admin will use it to build a simple .pkg installer, or if --dmg/-D is given, a Casper .dmg installer. In this situation, the --workspace/-W option can be used to provide a path to a "workspace" folder where the .pkg or .dmg is built before uploading to Casper. The workspace folder is remembered between uses of d3admin.


### edit

Packages in d3 can be edited with 

`d3admin edit <basename or edition> <options>`

Using the --walkthru/-w  option will present a menu with which you can edit all aspects of the package.

Without --walkthru, any options specified on the command line will be changed, others will be untouched.

### make live

All newly-added packages have the status ['pilot'](#pilot) and must be made ['live'](#live) (released) to be generally available in d3. 

`d3admin live <edition>`

will make the [edition](#edition) live, as long as the edition is currently a pilot.

Doing this will affect the [statuses](#status) of other packages with the same [basename](#basename):

- The package that was previously live will become [deprecated](#deprecated)
- Any pilot packages between the previously live one and this one will become [skipped](#skipped)
- Any newer packages than this one will remain [pilots](#pilot)

### delete

To delete a package from d3: 

`d3admin delete <basename or edition> <options>`

Options can be used to

- delete the Casper scripts associated with the package (if they aren't used elsewhere)
- leave the package in Casper while deleting it from d3
- archive the d3 package.


### package lists

The 'show' command of d3admin will present a list of packages on the server.

`d3admin show` or `d3admin show all`

will show the [edition](#edition) of every package in d3, along with its [status](#status), when and by whom it was added, and when and by whom it was released (made live).

The show command can take 'pilot', 'live', 'deprecated', 'skipped', and 'archived' to show just those packages.

### client reports

d3admin can generate reports about d3 packages installed on clients. It does this by querying the JSS for data about installed Casper package receipts, so the data is only as up-to-date as the most recent recon for each machine.

`d3admin report --type <type> <target>...`

The report types available are:

- pilot: targets are basenames. Lists machines piloting any edition of the basename
- installed: targets are basenames. Lists machines with any edition of the basename installed.
- deprecated: targets are basenames. Lists machines with out-of-date installs of the basename
- computer: targets are computer names. Lists all d3 packages installed on the computer(s)

More detailed info can be obtained by running one of the `d3 list-*` commands on the client machine(s) in question.

### d3admin and your keychain


([Table of contents](TOC#table-of-contents))