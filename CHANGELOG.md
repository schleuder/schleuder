Change Log
==========

This project adheres to [Semantic Versioning](http://semver.org/).

## Unreleased

### Fixed

* Stop leaking keywords to third parties by stripping HTML from multipart/alternative messages if they contain keywords. (#399)


## [3.3.0] / 2018-09-04

### Fixed

* Handle missing arguments for several keywords and reply with a helpful error-message.
* Send replies to keyword-usage and notices to admins regardless of the delivery-flag of their subscription. (#354)
* X-UNSUBSCRIBE will refuse to unsubscribe the last admin of a list. (#357)
* Handle "protected subjects" in a way that Thunderbird/Enigmail recognize. (#74)
* X-SET-FINGERPRINT will not anymore allow setting an empty fingerprint. (#360)


### Added

* To remove a fingerprint from a subscription one can use the new keyword X-UNSET-FINGERPRINT (#360).
* Extend the pseudoheaders configuration option to support 'sig' and 'enc' as configurable and sortable fields.


### Changed

* The output of the keywords 'X-ADD-KEY' and 'X-DELETE-KEY' now also show the "oneline"-format to represent keys (which includes fingerprint, primary email-address, date of generation and possible expiry). (#295)
* In the response to 'X-ADD-KEY', differentiate between 'newly imported' and 'updated' keys.
* Parse keywords up to the first line detected as mail content, this addresses a first part of #249.


## [3.2.3] / 2018-05-14

### Fixed

* `X-SUBSCRIBE` now in all cases correctly sets the values for admin and delivery_enabled, if they are given as third and fourth argument, respectively.
* To identify broken Microsoft Exchange messages, check if the headers include 'X-MS-Exchange' instead of specific domain names. Before this, we've missed mails sent by Exchange installations not operated by Microsoft or mails with a different "originating organisation domain" than Hotmail or Outlook. (#333)
* Do not anymore fail on emails containing any PGP boundaries as part of their plain text. As a sideeffect we will not anymore validate an email a second time. Hence, a message part containing an additional signature within an encrypted (and possibly signed) email won't be validated and removed. (#261)
* Exit with code 1 if a CLI-subcommand was not found (#339).
* Fix finding keywords in request-messages that were sent from Thunderbird/Enigmail with enabled "protected subject".
* Fix leaking the "protected subject" sent from Thunderbird/Enigmail.
* Error messages are converted into human readable text now, instead of giving their class-name. (#338)
* Require mail-gpg >= 0.3.3, which fixes a bug that let some equal-signs disappear under specific circumstances. (#287)


### Known issues

* With the current used mail library version schleuder uses, there are certain malformed emails that can't be parsed. See #334 for background. This will be fixed in future releases of the mail library.

### Added

* Enable to load external filters, similar to how we allow external plugins. (#282)

### Changed

* Use schleuder.org as website and team@schleuder.org as contact email.
* Check environment variable if code coverage check should be executed. (#342)
* Transform GPG fingerprints to upper case before saving to database. (#327)
* CLI-commands that (potentially) change data now remind the system admin to check file system permission if the command was run with root privileges. (#326)


## [3.2.2] / 2018-02-06

### Changed

* Temporarily depend on the ruby-library "mail" version 2.6. 2.7.0 seems to be a rough release (broke 8bit-characters, changed newline-styles) that needs to be ironed out before we can use it.
* Changed wording of error-message in case of a missing or incorrect "X-LIST-NAME"-keyword. (Thanks, anarcat!)
* Keys are now shuffled before refreshing them. This randomizes the way how we are querying keyservers for updated keys to avoid fingerprinting of a list's keyring.
* Be more robust when dirmngr fails while refreshing keys, especially when updating over an onion service. Fixes #309.


### Fixed

* Fix handling of emails with large first mime parts. We removed the code that limited the parsing of keywords to the first 1000 lines, as that broke the handling of certain large emails.
* Fix output of Keys with a broken character set. This mainly affected schleuder-api.
* Exit install-script if setting up the database failed.
* Reveal less errors to public, and improve messages to admins. Previously errors about list-config etc. would have been included in bounces to the sender of the incoming email. Now only the admins get to know the details (which now also include the list the error happened with). Email-bounces only tell about a fatal error — except if the list could not be found, that information is still sent to the sender of the incoming email.
* Make sure dirmngr is killed for a list after refreshing a list's keyring. Avoids servers getting memory exhausted. Fixes #289
* Fixed the API-daemon's interpretation of listnames that start with a number (previously the listname "1list" caused errors because it was taken as the integer 1).


## [3.2.1] / 2017-10-24

### Changed

* Explicitly depend on the latest version of ruby-gpgme (2.0.13) to force existing setups to update. This fixes the problem where unusable keys were not identified as such. (Previous versions of ruby-gpgme failed to properly provide the capabilities of a key.)


## [3.2.0] / 2017-10-23

### Added

* Internal footer: to be appended to each email that is sent to a subscribed address. Will not be included in messages to non-subscribed addresses. This change requires a change to the database, don't forget to run `schleuder install` after updating the code.
* Optionally use an OS-wide defined keyserver by configuring a blank value for the keyserver.
* Added keywords `X-RESEND-UNENCRYPTED` and `X-RESEND-CC-UNENCRYPTED` to enforce outgoing email(s) in cleartext regardless of whether we would find a key for the recipient or not.


### Changed

* Public footer: Whitespace is not anymore stripped from the value of public_footer.
* The API does not include anymore each key's key-data in response to `/keys.json`. This avoids performance problems with even medium sized keyrings.
* The short representation of GnuPG keys became more human-friendly. Besides the fingerprint we now show the email-address of the first UID, the generation-date, and optionally the expiration-date.
* Log the full exception when sending a message fails. (Thanks, Lunar!)
* When creating a new list, we do not anymore look for a matching key for the admin-address in the list's keyring. We don't want to look up keys for subscriptions by email at all. (This was anyway only useful in the corner case where you prefilled a keyring to use for the new list.)
* API: Access to `/status.json` is now allowed without authentication.
* Deprecate X-LISTNAME in favour of X-LIST-NAME, for the sake of consistency in spelling keywords (but X-LISTNAME is still supported). (Thanks, maxigas!)

### Fixed

* X-SUBSCRIBE now handles the combination of space-separated fingerprint and additional arguments (admin-flag, delivery-enabled-flag) correctly.
* Fixed broken encoding of certain character-sequences in encrypted+signed messages.
* X-LIST-KEYS again works without arguments.
* X-RESEND now checks the given arguments to be valid email-addresses, and blocks resending if any one is found invalid.
* X-RESEND now respects the encoding the mail was sent with. (Thanks, Lunar!)


## [3.1.2] / 2017-07-13

### Changed

* Sort lists alphabetically by email per default.

### Fixed

* Fix dropping mails on certain headers (e.g. spam), as the headers weren't checked properly so far.
* Fix processing of bounced messages. If a bounced messaged contained a PGP message (which most messages sent by schleuder have), schleuder tried to decrypt it before processing as a bounced message. This failed in nearly all cases, leading to double bounces. (#234)
* Fix reading messages with empty Content-Type-header. Some automatically sent messages don't have one.
* Do not try to fix text/plain messages from outlook (#246)


## [3.1.1] / 2017-06-24

### Added

* New cli-command `pin_keys` to pin the subscriptions of a list to a respective key (#225). Running this fixes the shortcoming of the code for list-migration mentioned below.

### Changed

* Allow to run `refresh_keys` only for a given list.

### Fixed

* **When migrating a v2-list, lookup keys for subscriptions** and assign the fingerprint if it was a distinct match. Otherwise people that had no fingerprint set before will receive plaintext emails — because in v3 we're not anymore looking up keys for subscriptions by email address. (To fix this for already migrated lists please use `schleuder pin_keys $listname`).
* When migrating a v2-list, assign the looked up fingerprint to an admin only if it was a distinct match.
* When migrating a v2-list, do not enable delivery for admins that weren't a member. (#213)
* When migrating a v2-list, subscribe duplicated members only once (#208)
* When migrating a v2-list, properly deal with admins that have no (valid) key. (#207)
* When creating a list, only use distinctly found keys for admins.
* Skip unusable keys when resending.
* Don't report unchanged keys when refreshing keys.
* Fix adding the subject-prefix to an empty subject (#226)
* Do not detect emails sent from cron-scripts as bounces (#205)
* Fix working with multipart/alternative-messages that contain inline OpenPGP-data. We're now stripping the HTML-part to enable properly handling the ciphertext.
* Validate that an email address can be subscribed only once per list.
* Fixed settings subscription-attributes (admin, delivery_enabled) when suscribing through schleuder-web.
* schleuder-api-daemon SysV init script: Fix formatting and styling, add recommend and required commands {status,reload,force-reload} by Lintian. (#230)
* Don't require database-adapter early. Helps when using a different database-system than sqlite.
* Fix text of admin-notification from plugin-runners.
* Avoid loops on notifying list admins (#229)


## [3.1.0] / 2017-05-21

### Added

* `X-GET-LOGFILE`. Sends you the logfile of the list.
* `X-ATTACH-LISTKEY`. Attaches the list's key to a message. Useful in combination with `X-RESEND`.
* `X-GET-VERSION`. Sends you the version of Schleuder that is running your list.
* API-endpoint to trigger sending the list's key to all subscriptions.

### Changed

* Don't write errors of list-plugins into the list of pseudo-headers. List-plugins must handle errors on their own.
* Allow request-plugins to return attachments.
* Fix x-get-key for multiple keys per match, and attach the resulting keys.
* Tolerate 0x-prefix on input for fingerprints of subscriptions.
* Tolerate spaces on input for fingerprints in keywords.
* `X-GET-KEY` returns keys as attachments now.
* `X-SIGN-THIS` returns attachments now, too.
* The texts that describe the forwarded automated messages now reflect that not all of those were bounces.
* Use single SQL-query instead of five, in select-statement in postfix/schleuder_sqlite.cf.
* Use sender() to specify the return-address, instead of setting a Return-Path.

### Fixed

* Make `public_footer` appear at the bottom of messages, not at the top.
* Remove excessive empty lines in output of refresh-keys.
* Amended list of dependencies in README.
* Fix `X-GET-KEY` for multiple keys per match.
* Also report if a key-import didn't change a present key.
* Fix bounce-address in postfix/schleuder_sqlite.cf.


## [3.0.4] / 2017-04-15

### Changed

* Harmonize format of key `check` and `update` texts.


### Fixed

* Fix unlegible messages (we mis-handled base64-encoded message-parts under some circumstances).
* Avoid run-on paragraphs in key `check` and `update` reports (Thanks, dkg!)
* Let schleuder-cli request check keys (allow /keys/check_keys.json to be reached).


## [3.0.3] / 2017-02-16

### Changed

* Require fingerprints of lists and subscriptions to be at least 32 characters long. Previously it was possible to assign shorter hexadecimal strings.
* Key lookup for arguments to X-keywords is stricter than before: if you supply a string containing an "@", gnupg will be told to only match it against email-addresses; if you send a hexadecimal string, gnupg will be told to only match it against fingerprints.
* Fixed and improved X-DELETE-KEY to only allow deletion of a single key, and only if no matching secret key is present.
* Fixed and improved X-FETCH-KEY to use the configured keyserver; to handle URLs, fingerprints, and email-addresses alike; and to send internationalized messages.
* Go back to make mock SKS-server listen on 127.0.0.1 — the former IP resulted in errors on some systems.


### Fixed

* Don't break multipart/alternative-parts when inserting our pseudo-headers.
* X-ADD-KEY handles inline content from Thunderbird correctly.
* X-SIGN-THIS now looks recursively for attachments to sign.
* Fixed unsubscribing oneself with X-UNSUBSCRIBE.
* Fixed setting fingerprint for other subscription than oneself with X-SET-FINGERPRINT.
* Better output of X-LIST-SUBSCRIPTIONS if no subscriptions are present.
* Sensible error message if X-GET-KEY doesn't find a matching key.
* Allow '0x'-prefix of fingerprints when given as keyword-argument.
* If no keyword generates output, a sensible error message is used.


### Added

* More rspec-tests.


## [3.0.2] / 2017-02-01

### Changed

* Use less usual IP and port number for mock SKS-server. Previously this conflicted with actual SKS-servers running on the same machine.


### Added

* Call refresh_keys in provided crontab-script.


### Fixed

* Fixed importing member-fingerprints when migrating a list.
* Fix clearing passphrase during list-migration with GnuPG 2.0.x by actually shipping the required pinentry-script.
* Corrected english phrasing and spelling for error message in case of wrong argument to listname-keyword. (Thanks, dkg!)


## [3.0.1] / 2017-01-26

### Fixed

* Fixed setting admin- and delivery-flags on subscription. Requests from schleuder-cli were interpreted wrongly, which led to new lists having no admins.
* A short description for the man-page of schleuder-api-daemon to satisfy the lintian.
* Listing openssl as dependency in README. If the openssl header-files are not present when eventmachine compiles its native code, schleuder-api-daemon cannot use TLS.
* Removed reference to Github from Code of Conduct.


## [3.0.0] / 2017-01-26

### Changed

* **API-keys always required!** From now on all requests to schleuder-api-daemon require API-keys, even via localhost. This helps protecting against rogue non-root-accounts or -scripts on the local machine.
* **TLS always used!** schleuder-api-daemon now always uses TLS.
* Switched project-site and git-repository to <https://0xacab.org/schleuder/schleuder>.
* Set proper usage flags when creating a new OpenPGP-key: the primary key gets "SC", the subkey "E". (Thanks, dkg!)
* Avoid possible future errors by ignoring every unknown output of gpg (like GnuPG's doc/DETAILS recommends). (Thanks, dkg!)
* Friendlier error message if delivery to subscription fails.
* Set list-email as primary address after adding UIDs. Previously it was a little random, for reasons only known to GnuPG.
* Only use temporary files where necessary, and with more secure paths.
* Tighten requirements for valid email-addresses a little: The domain-part may now only contain alphanumeric characters, plus these: `._-`
* Required version of schleuder-cli: 0.0.2.

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

The format of this file is based on [Keep a Changelog](http://keepachangelog.com/).

Template, please ignore:

## [x.x.x] / YYYY-MM-DD
### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security

