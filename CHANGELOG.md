Change Log
==========

This project adheres to [Semantic Versioning](http://semver.org/).

## [5.0.1] / 2025-06-08

### Fixed

* The removal of the GnuPG homedir is more reliable. Before, code might have run into issues due to time-of-check-to-time-of-use problems.
* Fixed code that rescues from failed message delivery to subscribers (and one more occurrence) (#538).
* Since ActiveRecord >= 7.1, the SQLite3 connection adapter relies on `Write-Ahead Logging` (`WAL`), by default, which significantly enhances read and write performance. Such performance gains aren't of concern in Schleuder environments. Besides, Postfix only supports the `delete` journal mode, which Schleuder now enforces. (#541)


## [5.0.0] / 2024-11-13

### Changed

* Require Ruby 3.1 or later, drop support for all earlier versions.
* Drop the default SKS keyserver. You can still specify your own, but by default now only keys.openpgp.org will be used to fetch keys by email address.
* The default umask now is `0077`, allowing access to newly created files and directories only for the owner. It is configurable in `schleuder.yml`.
* Don't suppress gpg's warnings about permissions and insecure memory, but log them in case they occur. (#496)
* Drop using dirmngr, use custom code to fetch keys from keyservers.
* Upgrade Active Record to version 7.1.
* Upgrade mail to 2.8.1.
* Check email address for `receive_from_subscribed_emailaddresses_only` in lower case letters to avoid wrong rejections.
* `mail-gpg` is no longer a dependency. We included the relevant parts of its code into our own code base to avoid problems with surprising decisions from upstream.
* The API now returns a detailed list of imported keys, so users can get earlier hints if the uploaded key e.g. was expired.
* In reply to a x-keyword, if the signing key is used by multiple subscriptions, in order to find the address to reply to, Schleuder now looks for a subscription that has an email matching the incoming From-header. As a fallback the first subscription using the siging key is used (as before).

### Added

* Optionally import selected keys from Autocrypt-headers and attachments of incoming emails, configurable for each list. See the code comment in `list-defaults.yml` for details.
* The umask is configurable in `schleuder.yml`.
* New dependency: libcurl and gem "typhoeus" (for networking).
* Lookup keys on a VKS keyserver (e.g. keys.openpgp.org) before the SKS keyserver.
* Configure a proxy to make HTTP requests (e.g. when fetching keys) through. This supports socks5(h) in order to route traffic through TOR.

### Fixed

* Fixed sending the list's key to all subscribers if `deliver_selfsent` is false.
* Fixed importing attached keys from some emails (like e.g. Thunderbird sends them).
* Fixed the `From:` header of notifications sent to the `superadmin` to ensure a fully qualified domain name is used.
* Fixed responding with an error message if an email contained only `x-add-key` but no other content.
* Improved parsing the arguments for `x-subscribe`: now unpexected values should lead to an error message instead of being interpreted strangely.
* Fixed not to collect keywords from emails if the email doesn't start with a keyword.


## [4.0.3] / 2022-04-12

### Changed

* Minor improvements of the German locales. 

### Fixed

* Since ActiveRecord >= 6.0, the SQLite3 connection adapter relies on boolean serialization to use 1 and 0, but does not natively recognize 't' and 'f' as booleans were previously serialized. Accordingly, handle conversion via a database migration of both column defaults and stored data provided by a user. (#505)
* Similar, due to ActiveRecord >= 6.0, it seems it's necessary to handle limits of string columns explicitly. Accordingly, handle this via a migration to add these limits to the relevant columns. This has been an upstream issue for quite some time, see https://github.com/rails/rails/issues/19001 for details.
* Fixed bug that circumvented filters when `bounces_drop_all` was set. (#508)


## [4.0.2] / 2021-07-31

### Fixed

* Fixed the verification of "encapsulated" PGP/MIME-messages as sent e.g. by KMail.


### Changed

* Remove the dependency on bigdecimal, since updating activerecord we don't need it anymore.
* Removed the dependency on the executables `hostname` and `whoami`.


## [4.0.1] / 2021-05-18

### Fixed

* `x-add-key` is able to handle attached binary key material. (#495)


## [4.0.0] / 2021-03-04

### Added

* Mandatory blank line: To separate keywords from email content, you *must* now insert a blank line between them.
* Provide systemd configs for weekly key maintenance. This relies on a working systemd-timesyncd. (#422)
* Support for Ruby 3.0.

### Changed

* Keyword arguments are now also looked for in the following lines, until a blank line or a new keyword-line is encountered.
* Allow to use the latest version of the gem `mail-gpg`. Our specs had been failing with versions > 0.4.2, but we found out it was our specs' fault.
* Change the way we force gpg to never-ever interactively ask for a passphrase. This should fix problems with specific combinations of GnuPG and GPGME.
* Drop support for Ruby 2.1, 2.2, 2.3 and 2.4, require Ruby 2.5.
* Drop support for GPG 2.0, require GPG 2.2.
* Drop support to migrate lists from version 2. This includes pin_keys code, which looked for subscriptions without an associated key, and tried to find a distinctly matching key. Originally, this was implemented to help with a shortcoming of code which handled version 2 to version 3 migration. (#411)
* "Plugins" are now called "keyword handlers", and they are implemented differently. If you use custom plugins you have to rewrite them (see an included keyword handler for implementation hints, it's rather simple). If you don't, this change doesn't affect you. One positive effect of this: if a message contains an unknown keyword, no keyword is being handled but the sender is sent an error message; thus we avoid half-handled messages.
* The key-attribute `oneline` has been renamed to `summary`. This affects also the http API.
* Allow only fingerprints as argument to X-DELETE-KEY. We want to reference keys only by fingerprint, if possible (as we do with other keywords already).
* Drop deprecated X-LISTNAME keyword. (#374)
* Downcase email addresses: Email addresses are downcased before saving.
* Update the dependency 'activerecord' to version 6.1.
* Update the dependency 'factory_bot' to version 6.0.
* Update the dependency 'sqlite3' to version 1.4.
* Update the dependency 'database_cleaner' to version 2.0.


## [3.6.0] / 2021-02-07

### Added

* List Option `set_reply_to_to_sender` (default: false): When enabled, the `Reply-To`-header of the emails sent from Schleuder will be set to the original sender's `Reply-To`-header. If the original sender did not supply a `Reply-To`-header, the original `From`-header will be used. (#298)
* List Option `munged_from` (default: false): When enabled, the `From`-header of the emails sent from Schleuder will contain the original sender's `From`-header included in the display name. To avoid DMARC issues, the `From`-header will stay the list's address. This results in a `From`-header such as: `"sender@sender.org via list@list.org" <list@list.org>`.

### Fixed

* Improve detection of bounces and thus fixing issues with falsely detected automatic messages. (#441)
* Properly validate email addresses for subscriptions. (#483 & #484)


## [3.5.3] / 2020-06-13

### Fixed

* Fix running specs on IPv6-only machines. (#472)


## [3.5.2] / 2020-06-09

### Fixed

* `x-add-key` is able to handle inline key material, followed by non-key material, like a signature included in the body. (#470)


## [3.5.1] / 2020-04-15

### Fixed

* `x-add-key` is able to handle mails with attached, quoted-printable encoded keys. Such mails might be produced by Thunderbird. (#467)


## [3.5.0] / 2020-03-30

### Added

* New option for lists to include their public keys in the headers of outgoing emails (conforming with Autocrypt, https://autocrypt.org/). Defaults to true. (#335)
* Add visual separator (78 dashes) to the end of the 'pseudoheaders' block: This should help users of Apple Mail, which jams this block and the body together. Hopefully, this change makes it easier to dinstiguish both parts from each other. (#348)
* `deliver_selfsent` per-list option to control whether subscribers get a copy of mail they sent themselves. (#365)
* Wrap pseudo headers if longer than 78 characters.

### Fixed

* Ensure UTF-8 as external encoding, convert any non-utf8 email to utf-8 or drop invalid characters. This should ensure that plain text emails in different charsets can be parsed (#409, #458, #460). Also we apply that conversion to the first text part after we parsed it for keywords, if no charset is set. This fixes #457. These changes introduce a new dependency `charlock_holmes`.
* Allow Jenkins job notifications to reach lists. Before, such mails were rejected due to being "auto-submitted".
* Do not recognize sudo messages as automated message. (#248)
* Fixed using x-attach-listkey with emails from Thunderbird that include protected headers.
* Handle incoming mails encrypted to an absent key, using symmetric encryption or containing PGP-garbage in a more graceful manner: Don't throw an exception, don't notify (and annoy) the admins, instead inform the sender of the mail how to do better. (#337)
* Add missing List-Id header to notification mails sent to admins. This should help with filtering such messages, which is currently not easy to do in a reliable way.
* Fix running Schleuder with ruby 2.7.
* Ensure that GnuPG never asks for a passphrase, even if it wants one. (#448)
* Be more precise about how many keys are in the keyring and how many are usable, when resending. (#429)
* Make it more clear what happens when resending an encrypted email fails (due to missing or too many matching keys), but falling back to unencrypted resend is allowed. (#343)
* Be more explicit that resending to other CC recipients has been aborted. (#265)


## [3.4.1] / 2019-09-16

### Fixed

* Do not crash on protected header emails generated by mutt (#430)
* Show an error message if `refresh_keys` is called with an email address for which no list exists.
* Fix recognizing keywords with "protected headers" and empty subject. Previously, if the subject was unset, keywords were not recognized and the original "protected headers" could leak. (#431)

### Changed

* Filter third party signatures on user-IDs when fetching or refreshing keys to mitigate against signature flooding. This works only if the version of gpg is 2.1.15 or newer. If the version is older, an email is being sent to the superadmin each time a key is fetched or keys are refreshed. See <https://dkg.fifthhorseman.net/blog/openpgp-certificate-flooding.html> for background information.


## [3.4.0] / 2019-02-14

### Fixed

* Stop leaking keywords to third parties by stripping HTML from multipart/alternative messages if they contain keywords. (#399)
* Avoid shelling out in a test-case to avoid an occasional error occurring in CI runs that complains about invalid data in ASCII-8BIT strings.

### Changed

* Update the dependency 'mail' to version 2.7.x., and allow carriage returns (CR) in test-cases as mail-2.7 puts those out.
* Update the dependency 'sqlite3' to version 1.3.x.
* Adapt fixtures and factories for factorybot version 5.x.
* Let schleuder-code load the filter files in test-mode, avoid explicit path names (which make headaches when running tests on installed packages).


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
