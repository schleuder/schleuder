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
1. mkdir /etc/schleuder /var/schleuder
2. cp etc/*.yml /etc/schleuder/
3. bundle install
4. bundle exec rake db:schema:load

Usage
-----
1. bundle exec ./bin/schleuder-newlist list@host admin@example.org [/path/to/public.key]
2. bundle exec ./bin/schleuder-subscribe list@host user@example.net DEADBEEFDEADBEEFDEADBEEF /tmp/user.asc

Todo:
* See <https://git.codecoop.org/schleuder/schleuder3/issues>.

Testing
-------

    SCHLEUDER_ENV=test SCHLEUDER_CONFIG=spec/schleuder.yml bundle exec rake db:create db:schema:load
    bundle exec rspec
