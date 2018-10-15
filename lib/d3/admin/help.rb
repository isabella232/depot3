### Copyright 2018 Pixar
###
###    Licensed under the Apache License, Version 2.0 (the "Apache License")
###    with the following modification; you may not use this file except in
###    compliance with the Apache License and the following modification to it:
###    Section 6. Trademarks. is deleted and replaced with:
###
###    6. Trademarks. This License does not grant permission to use the trade
###       names, trademarks, service marks, or product names of the Licensor
###       and its affiliates, except as required to comply with Section 4(c) of
###       the License and to reproduce the content of the NOTICE file.
###
###    You may obtain a copy of the Apache License at
###
###        http://www.apache.org/licenses/LICENSE-2.0
###
###    Unless required by applicable law or agreed to in writing, software
###    distributed under the Apache License with the above modification is
###    distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
###    KIND, either express or implied. See the Apache License for the specific
###    language governing permissions and limitations under the Apache License.
###
###


###
module D3
  module Admin
    # This just exists to get the very lengthy help texts out of the d3admin and
    # d3 executables.
    module Help
      extend self

      USAGE = "Usage: d3admin action target [options]"

      ### Return the d3amin help text
      ###
      ### @return [String] the d3admin help text
      ###
      def help_text
        helptxt = <<-ENDHELP

#{USAGE}

=== Actions <target> ===

  add <basename>                     Add a new pilot package
  edit <basename/edition>            Change properties of existing package
  live <edition>                     Make existing pilot package live
  delete <basename/edition>          Delete a package
  info <basename/edition>            Show details of an package
  search <basename/group>            List matching pkgs on the server
  report <basename/computer>         Report about receipts on computers
  config <setting/display>           d3admin configutation on this machine
  help                               Show this help.

=== Options ===

General:
  -w, --walkthru                     Interactively prompt for all options.
  -a, --auto-confirm                 Don't ask for confirmation before acting
  -h, --help                         Show this help text
  -H, --extended-help                Show extended help
  -D, --debug                        Show debug info and ruby backtraces

Action add:
  -i, --import <name or id>          Import an existing JSS package
  -W, --workspace <path>             Folder in which to build .dmgs & .pkgs
  -I, --no-inherit                   Don't inherit values from last package
  -s, --source-path <path>           Path to a .pkg, .dmg, or root-folder
  --dmg                              Build a .dmg, rather than a .pkg
  --preserve-owners                  Keep the ownership of contents in built .pkgs
  -p, --pkg-id <pkgid>               Apple pkg-identifier for built .pkgs

Action add and edit:
  -v, --version <version>            Version of the thing installed
  -r, --revision <revision>          Sequential packaging of the same version
  -n, --package-name <name>          The JSS 'display name' of the package
  -f, --filename <name>              The filename on the distribution point
  -d, --description <desc>           A textual description of this package
  -e, --pre-install <script>         Name, id, or path to pre-install script
  -t, --post-install <script>        Name, id, or path to post-install script
  -E, --pre-remove <script>          Name, id, or path to pre-remove script
  -T, --post-remove <script>         Name, id, or path to post-remove script
  -g, --auto-groups <groups>         Computer groups to get this pkg automatically
  -G, --excluded-groups <groups>     Computer groups that can't see this pkg
  -x, --prohibiting-processes <proc> Process name(s) that prevent installation
  -R, --reboot <y/n>                 Reboot required after install, puppies!
  -F, --remove-first <y/n>           Uninstall older versions before installing
  -u, --removable <y/n>              Can this package be uninstalled?
  -o, --oses <oses>                  OS limitations for installation.
  -c, --cpu <type>                   Limit installation to 'intel' or 'ppc'
  -C, --category <category>          The JSS Category for this package
  -X, --expiration <days>            Auto-uninstall if unused for <days>
  -P, --expiration-path(s) <path>    Path(s) to executable(s) that must be used
                                     (Multiple paths should be comma separated)

Action delete:
  --keep-scripts                     Keep pre-/post- scripts in Jamf Pro
  --keep-in-jss                      Delete pkg from d3 but leave in Jamf Pro

Action search or report:
  -S, --status <status>              Limit package list to this status
  --groups                           Target is a group name. Shows packages
                                       auto-installed or excluded for group

Action report:
  -S, --status <status>              Limit receipt list to this status
  -z, --frozen                       Limit receipt list to frozen receipts
  -q, --queue                        List puppy queue items rather than rcpts
  --computers                        Target is a computer name. Reports
                                        rcpts/puppies on that computer.

For details use -H or --extended-help

See also: https://github.com/PixarAnimationStudios/depot3/wiki/Admin

ENDHELP
      end # help text


      ### Return the d3amin help text
      ###
      ### @return [String] the d3admin help text
      ###
      def extended_help_text
        helptxt = <<-ENDHELP

d3admin is a tool for administering packages in d3, a package/patch
management & deployment tool that enhances the package-handling capabilities
of Jamf Pro.

For detailed documentation see:
https://github.com/PixarAnimationStudios/depot3/wiki/Admin

Important Terms:

- basename:   A word used to identify all packages that install any version of
              the same thing. E.g. 'filemaker' or 'transmogrifier' When a
              basename is used to specify a package, it refers to the currently
              live package for the basename. (see below)

- edition:    A unique identifier for a package or receipt in d3. It is made of
              the basename, version, and revision, joined by dashes.
              E.g. 'transmogrifier-2.2.1-2'
              Editions specify individual packages regardless of their status.

- live:       Each edition has a status: pilot, live, skipped, deprecated, or
              missing. Only one edition per basename can be 'live' a a time.
              When an edition is made live, it's approved for general deployment
              and is the edition installed with 'd3 install <basename>'. It will
              also auto-install on computers in the packages auto-groups, and it
              will auto-update on any computers with older editions of the same
              basename already installed.

- walkthru:   Any action can take the --walkthru option and you'll be prompted
              for targets (if needed) and options.
              Without --walkthru, you must provide all values with command-line
              options. Anything not on the command-line will use a default or
              inherited value, or cause an error if the option was required.

#{USAGE}

When refering to a package on the server, a basename imples the currently live
edition for that basename. Refering to a package by edition specifies an
individual package regardless of status.


=== Actions and their required targets & options ===

  add      Add a new pilot package to d3
             Target = basename unless -w
             Without -w, requires -v, -r, & -s

  edit     Change properties of existing package in d3
             Target = basename or edition unless -w

  live     Make existing pilot package live
             Target = edition unless -w

  delete   Delete an existing package from d3
             Target = basename or edition unless -w

  info     Show details of an package in d3
             Target = basename or edition unless -w

  search   Search for and list packages in d3.
              Target = search text (RegExp matching)
              No target = list all packages unless -w

  report   Report about d3 receipts or puppies on computers.
             Target = basename, or computer name unless -w

  config   Set up server info and default values for d3admin.
             Target = all, jss, db, dist, workspace,
             pkg-id-prefix or display. Defaults to all

             Using 'display' prints out the current admin config settings.

             Runs 'all' automatically on first run.

  help     Show this help. Use -H for extended help.


NOTE: Any action that requires stored passwords will prompt for your
keychain password if your login keychain is currently locked.

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

  -D, --debug                        Show LOTS of debugging info about whats
                                       happening. If there's a Ruby error,
                                       show the backtrace. Useful when reporting
                                       problems.

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

  --dmg                          When building from a root folder, build
                                       a .dmg, rather than the default .pkg

  --preserve-owners                  When building .pkgs, keep the ownership of
                                       the pkg-root folder. Default is to let
                                       the OS set ownership to standards based
                                       upon where items are installed.

  -p, --pkg-id <pkgid>               When building .pkgs, the apple package
                                       identifier, e.g. 'com.mycompany.app'
                                       Defaults to a prefix, plus the basename.
                                       The prefix is either the the apple_pkg_id_prefix
                                       setting from the d3admin config, or
                                       '#{D3::Admin::DFT_PKG_ID_PREFIX}'

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

  -x, --prohibiting-processes <proc>   Specify name(s) to match with process names
                                       as output by `/bin/ps -A -c -o comm`.
                                       If a match is found at install time,
                                       graceful quit will be attempted. Use "n" for 'none'

  -R, --reboot <y/n>                 Reboot is required after install.
                                       (PuppyTime!)
                                       Default is 'n'

  -u, --removable <y/n>              Can this package be uninstalled?
                                       Default is 'y'

  -F, --remove-first  <y/n>          Uninstall older versions before installing
                                       this one, if they are removable.
                                       Default is 'n'  (installs over the top)

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

  -P, --expiration-path(s) <path>    The path(s) to the executable(s) the must
                                       be used within the expiration period to
                                       avoid being uninstalled

Action delete:

  --keep-scripts                     Keep any scripts associated with this pkg
                                       in Jamf Pro. Note: scripts used by other
                                       packages or polices are never deleted.

  --keep-in-jss                      Leave the package in Jamf Pro after deleting
                                       it from d3. Note: packages used by
                                       policies are never deleted from Jamf Pro.


Action search:

  -S, --status <status>              Limit the packages listed to those with
                                       the given status. Can be used multiple
                                       times to see multiple statuses.

  --groups                           Instead of basenames, search computer
                                       group names and report packages scoped
                                       by those groups for auto-install or
                                       exclusion.

Action report:

  -S, --status <status>              Limit the receipts listed to those with
                                       the given status. Can be used multiple
                                       times to see multiple statuses.

  -z, --frozen                       Limit the receipts listed to frozen ones.

  -q, --queue                        Report pending puppy installs rather than
                                       receipts.

  --computers                        The target of the report is a computer name
                                       and the report is about receipts or
                                       pending puppy installs on that computer.


ENDHELP
      end # extended help text

    end # module help
  end # module admin
end # module D3
