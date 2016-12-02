Change Log
==========

This project adheres to [Semantic Versioning](http://semver.org/).

The format of this file is based on [Keep a Changelog](http://keepachangelog.com/).

## [Unreleased]


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

