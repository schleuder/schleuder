Change Log
==========

This project adheres to [Semantic Versioning](http://semver.org/).

The format of this file is based on [Keep a Changelog](http://keepachangelog.com/).

## Unreleased

### Changed

* **API-keys always required!** From now on all requests to schleuder-api-daemon require API-keys, even via localhost. This helps protecting against rogue non-root-accounts or -scripts on the local machine.
* Switched project-site and git-repository to <https://0xacab.org/schleuder/schleuder>.
* Set proper usage flags when creating a new OpenPGP-key: the primary key gets "SC", the subkey "E". (Thanks, dkg!)
* Avoid possible future errors by ignoring every unknown output of gpg (like GnuPG's doc/DETAILS recommends). (Thanks, dkg!)
* Friendlier error message if delivery to subscription fails.
* Set list-email as primary address after adding UIDs. Previously it was a little random, for reasons only known to GnuPG.
* Only use temporary files where neccessary, and with more secure paths.
* Tighten requirements for valid email-addresses a little: The domain-part may now only contain alpha-numeric characters, plus these: `._-`

### Added

* X-LISTNAME: A **new mandatory keyword** to accompany all keywords. From now on every message containing keywords must also include the listname-keyword like this: `X-LISTNAME: list@hostname`

  The other keywords will only be run if the given listname matches the email-address of the list that the message is sent to. This mitigates replay-attacks among different lists.
* Also send helpful message if a subscription's key is present but unusable.
* Provide simpler postfix integration, now using virtual_domains and an sql-script. (Thanks, dkg!)
* Enable refreshing keys from keyservers: A script that is meant to be run regularly from cron. It refreshes each key of each list one by one from a configurable keyserver, and sends the result to the respective list-admins.
* Import attached, ascii-armored keys from messages with `add-key`-keyword. (Thanks, Kéfir!)
* Check possible key-material for expected format before importing it. (Thanks, Kéfir!)

### Fixed

* Allow fingerprints to be prefixed with '0x' in `subscribe`-keyword.
* Also delete directory of list-logfile on deletion if that resides outside of the list-dir.
* Sign and possibly encrypt error notifications.
* Fix setting admin- and delivery-flags while subscribing.
* Fix subscribing from schleuder-cli.
* Fix finding subscriptions from signatures made by a signing-capable sub-key.


## [3.0.0.beta17] / 2017-01-12

### Changed

* Stopped using SCHLEUDER_ROOT in specs. Those make life difficult for packaging for debian.
* While running specs, ensure smtp-daemon.rb has been stopped before starting it anew.

### Added

* A Code of Conduct.


## [3.0.0.beta16] / 2017-01-11

### Fixed

* Fix running `schleuder migrate...`.
* Fix assigning list-attributes when migrating a list.

### Added

* Import the secret key and clear its passphrase when migrating a list from v2.
* More tests.


## [3.0.0.beta15] / 2017-01-10

### Changed

* Default `lists_dir` and `listlogs_dir` to `/var/lib/schleuder`.
* Use '/usr/local/bin' as daemon PATH in schleuder-api-daemon sysvinit
  script.

### Fixed

* Fix running for fresh lists if `lists_dir` is different from `listlogs_dir`
  (by creating logfile-basedir, closes Debian bug #850545).
* Fix error-message from ListBuilder if given email is invalid.
* Fix checking for sufficient gpg-version (previously '2.1' didn't suffice if
  '2.1.0' was required).

### Added

* Cron job file to check keys.
* Show when delivery is disabled for a subscription (in reply to
  'list-subscriptions'-keyword).
* Add timeout to default sqlite-config (avoids errors in the case that the
  DB-file is locked on first attempt).
* Provide method to call gpg-executable.
* Also add additional UIDs to generated PGP-keys when using gpg 2.0.
* Specs for ListBuilder.


## [3.0.0.beta14] / 2016-12-29

### Fixed

* Fix key expiry check
* Fix link to schleuder.nadir.org in List-Help header
* Fix deleting listdir

### Added

 * Runner and integration tests
 * More fixtures

## [3.0.0.beta13] / 2016-12-22

### Fixed

 * Fix creating new lists.


## [3.0.0.beta12] / 2016-12-22

### Changed

 * Show file permission warning if cert is being generated as root.
 * Use hard-coded defaults as base to merge config-file over.

### Added

 * New keyword `x-resend-cc` to send a message to multiple recipients that should know of each another. The ciphertext will be encrypted only once to all recipients, too.
 * More specs.
 * Skript for schleuder-api-daemon under sysvinit.

### Fixed

 * Fix tests for non-default listlogs_dir.
 * Fix pseudo-header "Sig" for unknown keys.
 * Fix adding subject_prefix_in for unencrypted messages.
 * Fix checking permissions of listdir and list.log for newly created lists.
 * Fix occasionally empty 'date'-pseudo-header.

## [3.0.0.beta11] / 2016-12-07

### Changed

 * Fixed recognition and validation of clearsigned-inline messages.
 * Fix log-file rotation (for list.log).
 * Show hint to set `use_tls: true` after generation of certificate.

### Added

 * During installation, show error message and exit if data of an installation of schleuder-2.x is found in the configured lists_dir.
 * More tests.


## [3.0.0.beta10] / 2016-12-05

### Changed

 * Fixed tarball to contain correct version and state of changelog.


## [3.0.0.beta9] / 2016-12-02

### Added

 * Include tarball into release.
 * Make basedir of list-logs configurable (`listlogs_dir`). No operational change with the default value.
 * Recognize "encapsulated" signatures (RFC 3156, 6.1). (These signatures might still be reported as invalid, that's a bug in mail-gpg which will probably be fixed in their next release.)
 * Make installed schleuder-files accessible for owner and group only.
 * Make list-logs accessible to owner and group only.

### Changed

 * Improved documentation.

### Fixed

 * Fix checking for empty messages for nested multiparts (e.g. Thunderbird with memoryhole-headers).
 * Fix `schleuder install` to respect config settings (e.g. `lists_dir`)

## [3.0.0.beta8] / 2016-11-27

### Changed

 * Add network and local-filesystem as dependencies in systemd-unit-file.
 * Improved documentation.

### Fixed

 * Declare dependency on thin.


## [3.0.0.beta7] / 2016-11-23

### Added

 * `man`-page for schleuder(8).
 * schleuder-api-daemon: optionally use TLS.
 * schleuder-api-daemon: authenticate client by API-key if TLS is used.

### Changed

 * Sign git-tags, gems, and tarballs as 0xB3D190D5235C74E1907EACFE898F2C91E2E6E1F3.
 * Rename schleuderd to schleuder-api-daemon.
 * schleuder-api-daemon: bind to `localhost` by default.
 * schleuder-api-daemon: changed name of `bind` config option to `host`.
 * schleuder-api-daemon: return 204 if not content is being sent along.
 * Refactor and improve model validations.

### Fixed

 * Fixed creating lists.
 * Fixed default config.
 * Log errors to syslog-logger in case of problems with list-dir.


## [3.0.0.beta6] / 2016-11-13

### Added

 * Add `-v`, `--version` arguments to CLI.
 * New model validators.
 * Translations (de, en) and better wording for validation error messages.
 * Specs (test-cases) for the list model.
 * Use Travis to automate testing.
 * Test listname to be a valid email address before creating list.
 * A simple contribution guide.
 * Check that GnuPG >= 2.0 is being used.
 * Enable to specify path to gpg-executable in GPGBIN environment variable.
 * A simple schleuder-only MTA to help with development.

### Changed

 * schleuderd: use GET instead of OPTIONS to work around bug in ruby 2.1.
 * Allow "inline"-pgp for request-messages (mail-gpg 0.2.7 fixed their issue).

### Fixed

 * Fix testing nested messages for emptiness.
 * Fix bouncing a message if it was found to be empty.
 * Fix truncated 'adding UID failed' message (transported via HTTP-headers).

## ...

---------

Template, please ignore:

## [x.x.x] / YYYY-MM-DD
### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security

