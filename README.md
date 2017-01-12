Schleuder, version 3
======================================

Schleuder is a gpg-enabled mailing list manager with resending-capabilities. Subscribers can communicate encrypted (and pseudonymously) among themselves, receive emails from non-subscribers and send emails to non-subscribers via the list.

Version 3 of schleuder is a complete rewrite, which aims to be more robust, flexible, and internationalized. It
also provides an API for the optional web interface called [schleuder-web](https://git.codecoop.org/schleuder/schleuder-web).

For more details see <https://schleuder.nadir.org/docs/>.

Requirements
------------
* ruby  >=2.1
* gnupg >=2.0
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
* thin
* mail-gpg
* sinatra
* sinatra-contrib


Installing Schleuder
------------

1. Download [the gem](https://git.codecoop.org/schleuder/schleuder3/raw/master/gems/schleuder-3.0.0.beta16.gem) and [the OpenPGP-signature](https://git.codecoop.org/schleuder/schleuder3/raw/master/gems/schleuder-3.0.0.beta16.gem.sig) and verify:
   ```
   gpg --recv-key 0xB3D190D5235C74E1907EACFE898F2C91E2E6E1F3
   gpg --verify schleuder-3.0.0.beta16.gem.sig
   ```

2. If all went well install the gem:
   ```
   gem install schleuder-3.0.0.beta16.gem
   ```

3. Set up schleuder:
  ```
  schleuder install
  ```
  This creates neccessary directories, copies example configs, etc. If you see errors about missing write permissions please follow the advice given.


For further information on setup and configuration please read <https://schleuder.nadir.org/docs/#setup>.


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

Please use
[schleuder-cli](https://git.codecoop.org/schleuder/schleuder-cli) to create and
manage lists from the command line.

Optionally consider installing
[schleuder-web](https://git.codecoop.org/schleuder/schleuder-web), the web
interface for schleuder. It enables list-admins to manage their lists through
the web instead of using [request-keywords](https://schleuder.nadir.org/docs/#subscription-and-key-management).



Todo
----

See <https://git.codecoop.org/schleuder/schleuder3/issues>.

Testing
-------
We use rspec to test our code. To setup the test environment run:


    SCHLEUDER_ENV=test SCHLEUDER_CONFIG=spec/schleuder.yml bundle exec rake db:create db:schema:load

To execute the test suite run:

    bundle exec rspec

We are working on extendig the test coverage.

Contributing
------------

Please see [CONTRIBUTING.md](CONTRIBUTING.md).


License
-------

GNU GPL 3.0. Please see [LICENSE.txt](LICENSE.txt).


Alternative Download
--------------------

Alternatively to the gem-files you can download the latest release as [a tarball](https://git.codecoop.org/schleuder/schleuder3/raw/master/gems/schleuder-3.0.0.beta16.tar.gz) and [its OpenPGP-signature](https://git.codecoop.org/schleuder/schleuder3/raw/master/gems/schleuder-3.0.0.beta16.tar.gz.sig).
