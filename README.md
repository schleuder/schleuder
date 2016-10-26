Schleuder, version 3
======================================

Schleuder is a gpg-enabled mailing list manager with resending-capabilities. Subscribers can communicate encrypted (and pseudonymously) among themselves, receive emails from non-subscribers and send emails to non-subscribers via the list.

Version 3 of schleuder is a complete rewrite, which aims to be more robust, flexible, and internationalized. It
also provides an API for the optional web interface called [webschleuder](https://git.codecoop.org/schleuder/webschleuder3).

For more details or documentation see <https://schleuder2.nadir.org/documentation/v2.2/index.html> (for now).

Requirements
------------
* ruby  >=2.1
* gnupg >=2.0 (if possible use >= 2.1.14)
* gpgme
* sqlite3

On Debian-based systems, install these via

    apt-get install ruby2.1-dev gnupg2 libgpgme11-dev libsqlite3-dev


We **recommend** to also run a random number generator like [haveged](http://www.issihosts.com/haveged/). This ensures Schleuder won't be blocked by lacking entropy, which otherwise might happen especially during key generation.

On Debian based systems, install it via

    apt-get install haveged


Additionally these **rubygems** are required (will be installed automatically unless present):

* rake
* active_record
* sqlite3
* thor
* mail-gpg
* sinatra
* sinatra-contrib


Installing Schleuder
------------

1. Download [the gem](https://git.codecoop.org/schleuder/schleuder3/raw/master/gems/schleuder-3.0.0.beta5.gem) and [the OpenPGP-signature](https://git.codecoop.org/schleuder/schleuder3/raw/master/gems/schleuder-3.0.0.beta5.gem.sig) and verify:
   ```
   gpg --recv-key 0x75C9B62688F93AC6574BDE7ED8A6EF816E1C6F25
   gpg --verify schleuder-3.0.0.beta5.gem.sig
   ```

2. If all went well install the gem:
   ```
   gem install schleuder-3.0.0.beta5.gem
   ```

3. Set up schleuder:
  ```
  schleuder install
  ```
  This creates neccessary directories, copies example configs, etc. If you see errors about missing write permissions please follow the advice given.


Command line usage
-----------------

See `schleuder help`.

E.g.:

    Commands:
      schleuder check_keys                    # Check all lists for unusable or expiring keys and send the results to the list-admins. (This is supposed...
      schleuder help [COMMAND]                # Describe available commands or one specific command
      schleuder install                       # Set up Schleuder initially. Create folders, copy files, fill the database, etc.
      schleuder version                       # Show version of schleuder
      schleuder work list@hostname < message  # Run a message through a list.

List administration
-------------------

You probably want to install
[schleuder-conf](https://git.codecoop.org/schleuder/schleuder-conf), too.
Otherwise you'd need to edit the database-records manually to change
list-settings, subscribe addresses, etc.

Optionally consider installing
[webschleuder](https://git.codecoop.org/schleuder/webschleuder3), the web
interface for schleuder.



Todo
----

See <https://git.codecoop.org/schleuder/schleuder3/issues>.

Testing
-------

    SCHLEUDER_ENV=test SCHLEUDER_CONFIG=spec/schleuder.yml bundle exec rake db:create db:schema:load
    bundle exec rspec


Contributing
------------

To contribute please follow this workflow:

1. Talk to us! E.g. create an issue about your idea or problem.
2. Fork the repository and work in a meaningful named branch that is based off of our "master".
3. Commit in rather small chunks but don't split depending code across commits. Please write sensible commit messages.
4. If in doubt request feedback from us!
5. When finished create a merge request.


Thank you for your interest!
