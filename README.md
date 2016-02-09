Schleuder, version 3
======================================

Schleuder is a gpg-enabled mailinglist with remailing-capabilities. Subscribers can communicate encrypted (and pseudonymously) among themselves, receive emails from non-subscribers and send emails to non-subscribers via the list.

Version 3 of schleuder is a complete rewrite, which aims to be more robust, flexible, and internationalized. It 
also provides an API for the optional web interface called [webschleuder](https://git.codecoop.org/schleuder/webschleuder3).

For more details or documentation see <https://schleuder2.nadir.org/documentation/v2.2/index.html> (for now).

Requirements
------------
* ruby  >=2.1
* gnupg >=2.1
* and some ruby gems

Installation
------------
1. Download and verify the gem:

   ```
   wget https://schleuder.nadir.org/download/schleuder-3.0.0.beta1.gem
   wget https://schleuder.nadir.org/download/schleuder-3.0.0.beta1.gem.sig
   gpg --recv-key 0x75C9B62688F93AC6574BDE7ED8A6EF816E1C6F25
   gpg --verify schleuder-3.0.0.beta1.gem.sig
   ```

2. If all went well install the gem:
   ```
   sudo gem install --no-user-install schleuder-3.0.0.beta1.gem
   ```
   * Explanation for advanced admins: schleuder should be installed as root system-wide because it must be executable for both, root (to complete the setup, see next step) and an ordinary user (to run schleuder). Alternatively you could install it for both users separately or do the setup-steps manually (TODO: document the setup-steps).

3. Set up schleuder:
  ```
  sudo schleuder install
  ```
  This creates neccessary directories, copies example configs, etc.


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
