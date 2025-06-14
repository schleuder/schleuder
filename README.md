Schleuder
======================================

Schleuder is a gpg-enabled mailing list manager with resending-capabilities. Subscribers can communicate encrypted (and pseudonymously) among themselves, receive emails from non-subscribers and send emails to non-subscribers via the list.

It aims to be robust, flexible, internationalized and also provides an API for the optional web interface called [schleuder-web](https://0xacab.org/schleuder/schleuder-web).

For more details see <https://schleuder.org/docs/>.

Maintainers wanted!
-------------------
This project needs additional maintainers. All of us in the team have hardly any time for the project anymore. We don't want Schleuder to die, and we're not dropping it right now. But for a sustainable future, Schleuder needs new humans to care for it.

For details please see <https://0xacab.org/schleuder/schleuder/-/issues/540>.

Requirements
------------
* ruby >=2.7
* gnupg >=2.2
* gpgme
* sqlite3
* openssl
* icu
* libcurl

*If you use Debian buster, CentOS 7 or Archlinux, please have a look at the [installation docs](https://schleuder.org/schleuder/docs/server-admins.html#installation). We do provide packages for those platforms, which simplify the installation a lot.*

We **recommend** to also run a random number generator like [haveged](http://www.issihosts.com/haveged/). This ensures Schleuder won't be blocked by lacking entropy, which otherwise might happen especially during key generation.


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

1. Download [the gem](https://schleuder.org/download/schleuder-5.0.1.gem) and [the OpenPGP-signature](https://schleuder.org/download/schleuder-5.0.1.gem.sig) and verify:
   ```
   gpg --recv-key 0xB3D190D5235C74E1907EACFE898F2C91E2E6E1F3
   gpg --verify schleuder-5.0.1.gem.sig
   ```

2. Install required packages to facilitate installation of the gem (command tested on Deban version 12 - codename bookworm)
   ```
   apt install autoconf g++ gcc libsqlite3-dev libssl-dev libxml2-dev libz-dev make ruby-bundler ruby-dev ruby-rubygems
   ```

3. If all went well install the gem:
   ```
   gem install schleuder-5.0.1.gem
   ```

4. Set up schleuder:
  ```
  schleuder install
  ```
  This creates necessary directories, copies example configs, etc. If you see errors about missing write permissions please follow the advice given.


For further information on setup and configuration please read <https://schleuder.org/schleuder/docs/server-admins.html>.


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
[schleuder-cli](https://0xacab.org/schleuder/schleuder-cli) to create and
manage lists from the command line.

Optionally consider installing
[schleuder-web](https://0xacab.org/schleuder/schleuder-web), the web
interface for schleuder. It enables list-admins to manage their lists through
the web instead of using [request-keywords](https://schleuder.org/docs/#subscription-and-key-management).



Todo
----

See <https://0xacab.org/schleuder/schleuder/issues>.

Testing
-------
We use rspec to test our code. To setup the test environment run:


    SCHLEUDER_ENV=test SCHLEUDER_CONFIG=spec/schleuder.yml bundle exec rake db:init

To execute the test suite run:

    bundle exec rspec

We are working on extendig the test coverage.

Contributing
------------

Please see [CONTRIBUTING.md](CONTRIBUTING.md).


Mission statement
-----------------

Please see [MISSION_STATEMENT.md](MISSION_STATEMENT.md).


Code of Conduct
---------------

We adopted a code of conduct. Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).


License
-------

GNU GPL 3.0. Please see [LICENSE.txt](LICENSE.txt).


Alternative Download
--------------------

Alternatively to the gem-files you can download the latest release as [a tarball](https://schleuder.org/download/schleuder-5.0.1.tar.gz) and [its OpenPGP-signature](https://schleuder.org/download/schleuder-5.0.1.tar.gz.sig).
