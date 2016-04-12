# Change History

## v3.0.9 - 2016-04-11

- d3: better text feedback during manual installs.
- Package.all_filenames: limit list to d3 packages, not all JSS packages.
- Client::Receript.add\_receipt: log "replaced" only when really replacing.
- d3helper: clean up rcpt import, add pkg ids, admin name.
- README: better contact info
- lots of comment changes for YARD parsing fix
- Package::Validate.check\_for\_exlusions: bugfix
- Added D3::DEBUG_FILE support for d3, d3admin, & d3helper. Used getting debug logging/output when d3 command is embedded in other tools. If the file /tmp/d3debug-on exists, it's the same using the --debug option
- d3: actions that don't need server connections can be done witout root: list-installed, list-manual, list-pilot, list-frozen, list-queue

## v3.0.8 - 2016-04-01

- Fix: pre- and post-install script failures no longer cause fatal exceptions, halting sync. Instead the error is reported, the package skipped, and the sync continues.

## v3.0.7 - 2016-04-01

Initial open source release

## v3.0.6 - 2016-03-28

Pixar internal release of v3.
