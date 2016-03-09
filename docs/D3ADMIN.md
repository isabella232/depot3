# d3admin
---

## NAME

   **d3admin** - A command-line tool for creating and maintaining packages in the [d3 package/patch management & deployment system](Intro.md)

## SYNOPSIS

   d3admin action target [target...] [options]

## CONTENTS

## DESCRIPTION

#### Important vocabulary

Please see [the introduction to d3](Intro.md#basic-vocabulary) for some basic vocabulary fundamental to understanding any discussion of d3. 

d3admin is a tool for administering packages in d3. It can be used to:

* Add a new pilotable package to d3
* Import Casper packages into d3.
* Change properties of a package in d3
* Make a package live
* Delete a package from d3
* Show details of a package in d3
* Show lists of packages in d3
* Report d3 packages installed on client machines as of the last recon
* Configure up server info and default values for d3admin.

Each action takes one or more targets to work on, and can accept options.

All actions can take the --walkthru option, in which case the user will be prompted for a target and all options.  Without --walkthru, required options must be provided on the commandline, 
and options not provided will use inherited or default values.

d3admin cannot be used as the superuser (root) and perhaps as other users depending on site configuration. The username performing certain actions is recorded in the d3 package data, and needs to be a meaningful name.

This manpage describes the d3admin executable. For a full discussion of using d3admin in context, please see [The d3admin manual](Admin.md)


## DETAILS
```

=== Actions and their required targets & options ===

  add          Add a new pilot package to d3
                     Target = basename unless -w
                     Without -w, requires -v, -r, & -s

  edit         Change properties of existing package in d3
                     Target = basename or edition unless -w

  live         Make existing pilot package live
                     Target = edition unless -w

  delete       Delete an existing package from d3
                     Target = basename or edition unless -w

  info         Show details of an package in d3
                     Target = basename or edition unless -w

  show         Show a list of packages in d3
                     Target = all, pilot, live, skipped, deprecated,
                     missing, auto, or excluded
                     Defaults to all. auto and excluded require -S

  report       Report what's installed on clients as of the last recon.
                     Target = basename, or computer name unless -w
                     Optional --type can be installed, pilot,
                     deprecated, frozen, or receipts. Defaults to installed.

  config       Set up server info and default values for d3admin.
                     Target = all, jss, db, dist, workspace, pkg-id-prefix
                     Defaults to all
                     Runs 'all' automatically on first run.

  help         Show this help. Use -H for extended help.



=== Options ===

Non-required options for add will use inherited or default values if unspecified.

General:

  -w, --walkthru                     Interactively prompt for all options.
                                       Options provided on the commandline are
                                       ignored. Without -w, anything NOT provided
                                       on the command-line will use a default or
                                       inherited value or will raise an error.

  -a, --auto-confirm                 Don't ask for confirmation before making
                                       changes. For use in automation.
                                       BE VERY CAREFUL

  -H, --help                         Show this help text


Action add:

  -i, --import <name or id>          When the action is 'add', import an existing
                                       JSS package into d3 by display-name or id.
                                       Requires -w or  -v & -r

  -W, --workspace <path>             Folder in which to build .dmgs & .pkgs
                                       default is your home folder.
                                       Preserved between uses of d3admin.

  -I, --no-inherit                   Don't inherit default values from most
                                       recent package with the same basename.

  -s, --source-path <path>             Path to a .pkg, .dmg, or root-folder
                                       from which to build one

  -D, --dmg                          When building from a root folder, build
                                       a .dmg, rather than the default .pkg

  --preserve-owners                  When building .pkgs, keep the ownership of
                                       the pkg-root folder. Default is to let
                                       the OS set ownership to standards based
                                       upon where items are installed.

  -p, --pkg-id-prefix <pfx>          When building .pkgs, prepend this to the
                                       basename to get the apple pkg-identifier
                                       e.g. 'com.pixar.d3' gives the identifier
                                       'com.pixar.d3.foo' for basename 'foo'
                                       This value will be stored between uses of
                                       d3admin and used as default thereafter

Action add and edit:

  -v, --version <version>            Version of the thing installed by the
                                       package, e.g. "2.5", "1.1a3".
                                       May not contain a '-', which will be
                                       converted to '_'

  -r, --revision <revision>          Package-revision.
                                       This integer represents how many times
                                       a particular version of a basename has
                                       been added to d3.

  -n, --package-name <name>          The JSS 'display name' of the package.
                                       Must be unique in the JSS
                                       Defaults to <edition>.<pkg_type>
                                       e.g. myapp-2.3a1-2.pkg

  -f, --filename                     The name of the installer file on the
                                       master distribution point. When uploading,
                                       the file will be renamed to this.
                                       If the installer is a .pkg bundle, it
                                       will be zipped, and '.zip' appended
                                       automatically when uploaded.
                                       Defaults to <edition>.<pkg_type>
                                       e.g. myapp-2.3a1-2.pkg

  -d, --description <desc>           A textual description of this package,
                                       and any notes or comments about it.

  -e, --pre-install <script>         The name or id of an existing JSS script,
                                       or the path to a file with a new script.
                                       This script is run before installing.
                                       Use "n" for 'none'.
                                       See the full documentation for details.

  -t, --post-install <script>        As for pre-install, but the script to run
                                       after installing the package.

  -E, --pre-remove <script>          As for pre-install, but the script to run
                                       before uninstalling the package.

  -T, --post-remove <script>         As for pre-install, but the script to run
                                       after uninstalling the package.

  -g, --auto-groups <groups>        Comma-separated list of JSS computer groups
                                       whose members get this pkg automatically.
                                       Use '#{D3::STANDARD_AUTO_GROUP}'
                                       to install on all machines.
                                       Use "n" for 'none'.

  -G, --excluded-groups <groups>      Comma-separated list of JSS computer groups
                                       whose members can't install this pkg
                                       without using force.
                                       Use "n" for 'none'.

  -x, --prohibiting-process <proc>   Specify a name to match with process names
                                       as output by `/bin/ps -A -c -o comm`.
                                       If a match is found at install time,
                                       prevents installation. Use "n" for 'none'

  -R, --reboot                       Reboot is required after install,
                                       shows puppies!
                                       Default is to not require reboot

  -F, --remove-first                 Uninstall older versions before installing
                                       this one, if they are removable.
                                       Default is to install over the top

  -u, --removable <y/n>              Can this package be uninstalled?
                                       Default is y

  -o, --oses <oses>                  Comma-separated list of OS version to allow
                                       installation of this package.
                                         e.g. 10.5.8, 10.6.x
                                       Use '>=' to set a min. OS version
                                         e.g. >=10.6.0
                                       Use "n" for no limitation

  -c, --cpu <type>                   Limit to cpu type: 'ppc' or 'intel'
                                       Use "n" for no limitation.

  -C, --category <category>          The JSS Category for this package
                                       Use "n" for none

  -X, --expiration <days>            How many days of no use before this package
                                       uninstalls itself. Pkg must be removable,
                                       and expiration must be allowed in the
                                       client config.

   --expiration-path <Path>          The path to the app the must be used within
                                       the expiration period to avoid being
                                       uninstalled

Action delete:

  --delete-scripts                   Delete any scripts associated with this pkg
                                       if they aren't in use elsewhere. Those in
                                       use will be reported.

  --keep-in-jss                      Leave the package in the JSS after deleting
                                       it from d3


Action show:

  -S, --scoped-groups                When using 'auto' or 'excluded' with the
                                       'show' action, one or more JSS computer
                                       groups (comma-separated) to report on.

Action report:

  --type <report type>               The type of report to generate about the
                                     target(s). One of:
                                       'pilot' - clients piloting the target
                                       'deprecated' - clients with old editions
                                          of the target installed
                                       'frozen' - clients with frozen editions
                                          of the target installed
                                       'installed' - clients with any edition
                                          of the target installed
                                       'computer' - all d3 packages installed
                                          on target computer
                                     Default is 'installed'
```

## EXAMPLES
See [the d3admin manual](Admin.md)

## SEE ALSO
[d3](d3.md), [The d3admin manual](Admin.md), [puppytime](puppytime.md), [d3helper](d3helper.md)

## AUTHORS
d3admin was written by Chris Lasell at Pixar Animation Studios \<[chrisl@pixar.com](mailto:chrisl@pixar.com)\>

## COPYRIGHT