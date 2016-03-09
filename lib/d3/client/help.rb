### Copyright 2016 Pixar
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


module D3
  class Client < JSS::Client
    module Help
      extend self

      USAGE = "Usage: d3 action [target [...]] [options]\nUse -H for help"

      ### Return the d3amin help text
      ###
      ### Its far easier and more flexible to maintain the visual layout of
      ### this complex help as a single large heredoc, than it is to build it
      ### programmatically from the commands and options hashes
      ### The downside is that it must be manually updated when those hashes
      ### change.
      ###
      ### @return [String] the d3 help text
      ###
      def help_text
        helptxt = <<-ENDHELP

d3: package/patch management & deployment tool to enhance the package-
handling capabilities of the Casper Suite from JAMF Software, LLC.

#{USAGE}

All actions have a 1-2 character shortcut.

For details see http://some/url/here

Actions:
  install   i  <basename/edition>       - Install pkgs or queue for logout
  uninstall u  <basename>               - Uninstall pkgs
  freeze    f  <basename>               - Stop auto-updates of this basename
  thaw      t  <basename>               - Resume auto-updates of this basename
  dequeue   dq <basename>               - Remove a pending logout install
  sync      s                           - Update rcpts, update installed pkgs,
                                          do group-based auto-installs, &
                                          uninstall expired pkgs
  help                                  - Show this help info

List Actions:
  list-available  la                    - Live pkgs available to this computer
  list-installed  li                    - Pkgs installed on this comptuer
  list-manual     lm                    - Manually installed pkgs
  list-pilots     lp                    - Pilots on this machine
  list-frozen     lf                    - Frozen pkgs on this machine
  list-queue      lq                    - Pending puppy (logout) installs
  list-details    ld <basename/edition> - Pkg details
  list-files      ls <basename/edition> - Files installed by the pkg
  query-file      qf <path>             - Which pkgs install <path>

Options:
  -q, --quiet                  - Be as silent as possible,
                                 use twice for more silence
  -v, --verbose                - Give more detail about what's happening,
                                 use twice for more details
  -p, --puppies                - Do puppy installs now, instead of queuing
                                 When used with 'install', the pkgs
                                 pkgs are installed immediately
                                 When used with 'sync' any queued puppies
                                 are installed immediately
  -f, --force                  - Force d3 to perform unnatural acts
  -a, --admin <admin>          - The name of the admin using d3
  -N, --no-puppy-notification  - Don't run the puppy-notification policy
  -e, --expiration <days>      - With 'install', set a custom expiration
                                 if the pkg is expirable
  -d, --debug                  - Set verbosity and logging to full blast
  -V, --version                - Show d3 version info
  -H, --help                   - Show this help info


Notes
 - All <targets> can be a list of several, space-separated
 - When a basename is given as an argument, the currently live, queued,
   or installed edition is used

ENDHELP
        helptxt
      end # help_text

    end # module help
  end # class
end # module D3

