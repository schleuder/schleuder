Schleuder3 — Schleuder on ActiveRecord.
======================================

Does not include a web-interface, but provides a ready to use foundation for it.

Is slower starting up than schleuder-2, but more robust, modern and beautiful.
Comes with internationalized error-messages.

Requirements
------------
* ruby  >=2.1
* gnupg >=2.1

Installation
------------
3. bundle install
4. bundle exec rake db:schema:load
5. bundle exec ./bin/schleuder install

Usage
-----

See `schleuder help`.

E.g.:

    Commands:
      schleuder check_keys                    # Check all lists for unusable or expiring keys and send the results to the list-admins. (This is supposed...
      schleuder help [COMMAND]                # Describe available commands or one specific command
      schleuder install                       # Set up Schleuder initially. Create folders, copy files, fill the database, etc.
      schleuder version                       # Show version of schleuder
      schleuder work list@hostname < message  # Run a message through a list.

You probably want to install schleuder-conf, too. Otherwise you'd need to edit the database-records manually to change list-settings, subscribe addresses, etc.

Todo:
* See <https://git.codecoop.org/schleuder/schleuder3/issues>.

Testing
-------

    SCHLEUDER_ENV=test SCHLEUDER_CONFIG=spec/schleuder.yml bundle exec rake db:create db:schema:load
    bundle exec rspec
