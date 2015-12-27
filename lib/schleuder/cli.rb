require_relative '../schleuder'
require 'thor'
require 'yaml'
require 'gpgme'

module Schleuder
  class Cli < Thor

    desc 'version', 'Show version of schleuder'
    def version
      say Schleuder::VERSION
    end

    desc 'work list@hostname < message', 'Run a message through a list.'
    def work(listname)

      message  = STDIN.read

      error = Schleuder::Runner.new.run(message, listname)
      if error.kind_of?(StandardError)
        fatal error
      end
    rescue => exc
      begin
        Schleuder.logger.fatal(exc.message, message)
        say I18n.t('errors.fatalerror')
      rescue => e
        # Give users a clue what to do in case everything blows up.
        # As apparently even the logging raised exceptions we can't even store
        # any information in the logs.
        fatal "A serious, unhandleable error happened. Please contact the administrators of this system or service and provide them with the following information:\n\n#{e.message}"
      end
      exit 1
    end

    desc 'check_keys', 'Check all lists for unusable or expiring keys and send the results to the list-admins. (This is supposed to be run from cron weekly.)'
    def check_keys(listname=nil)

      Schleuder::List.all.each do |list|
        I18n.locale = list.language

        text = list.check_keys

        if text && ! text.empty?
          msg = "#{I18n.t('check_keys_intro', email: list.email)}\n\n#{text}"
          list.logger.notify_admin(msg, nil, I18n.t('check_keys'))
        end
      end
    end

    method_option :schleuderpath, banner: '/path/to/code', desc: 'Path to code of schleuder (if not installed from gem)'
    desc 'install [ --schleuderpath=/path/to/code ]', "Set up Schleuder initially. Create folders, copy files, fill the database."
    def install
      if `id -u`.to_i > 0
        fatal "root-privileges required"
      end

      if options[:schleuderpath]
        if ! File.directory?(options[:schleuderpath])
          fatal "No such directory '#{options[:schleuderpath]}'"
        end
        path = options[:schleuderpath]
      else
        spec = Gem::Specification.find_by_name('schleuder')
        path = spec.gem_dir
      end

      FileUtils.mkdir_p %w[/var/schleuder /var/schleuder/lists /etc/schleuder]
      Dir[File.join(path, "etc/*")].each do |file|
        target = "/etc/schleuder/#{File.basename(file)}"
        if ! File.exists?(target)
          FileUtils.cp file, target
        end
      end
      say "Now please adapt /etc/schleuder/schleuder.yml to your needs. If you choose a different DBMS than sqlite (e.g. mysql, postgresql) don't forget to create the database you configured and install the ruby-bindings (e.g. `gem install mysql`)."

      # TODO: test if database exists and is prepared already.
      # Step 2
      say "Next: Filling the database."
      answer = ask "Ready? [yN] "
      if answer.downcase != 'y'
        say "Cancelled."
        exit
      end

      say `cd #{path} && rake db:schema:load`

      say "
      Schleuder has been set up. You can now create a new list using schleuder-conf.
      We hope you enjoy!"
    rescue => exc
      fatal exc.message
    end

    desc 'migrate-v2-list /path/to/listdir', 'Migrate list from v2.2 to v3.'
    def migrate_v2_list(path)
      dir = Pathname.new(path)
      if ! dir.readable? || ! dir.directory?
        fatal "Not a readable directory: `#{path}`."
      end

      %w[list.conf members.conf pubring.gpg].each do |file|
        if ! (dir + file).exist?
          fatal "Not a complete schleuder v2.2 listdir: missing #{file}"
        end
      end

      conf = YAML.load(File.read(dir + 'list.conf'))
      if conf.nil? || conf.empty?
        fatal "list.conf is blank"
      end
      listname = conf['myaddr']
      if listname.nil? || listname.empty?
        fatal "myaddr is blank in list.conf"
      end

      # Identify list-fingerprint.
      ENV['GNUPGHOME'] = dir.to_s
      # Save all the keys for later import, we shouldn't change ENV['GNUPGHOME'] later.
      #allkeys = GPGME::Key.find(:public, '')
      listkey = GPGME::Key.find(:public, "<#{listname}>")
      if listkey.size == 1
        fingerprint = listkey.first.fingerprint
      else
        fingerprint = nil
        error 'Failed to identify fingerprint of GnuPG key for list, you must set it manually to make the list operational!'
      end

      # Create list.
      list = Schleuder::ListBuilder.new(listname, nil, nil, fingerprint).run

      # Set list-options.
      List.configurable_attributes.each do |option|
        option = option.to_s
        if conf[option]
          value = if option.match(/^keywords_/)
                    filter_keywords(conf[option])
                  else
                    conf[option]
                  end
          list.set_attribute(option, value)
        end
      end

      # Set changed options.
      { 'prefix' => 'subject_prefix',
        'prefix_in' => 'subject_prefix_in',
        'prefix_out' => 'subject_prefix_out',
        'dump_incoming_mail' => 'forward_all_incoming_to_admins',
        'receive_from_member_emailaddresses_only' => 'receive_from_subscribed_emailaddresses_only',
        'bounces_notify_admin' => 'bounces_notify_admins',
        'max_message_size' => 'max_message_size_kb'
      }.each do |old, new|
        if conf[old] && ! conf[old].to_s.empty?
          list.set_attribute(new, conf[old])
        end
      end
      list.save!

      # Import keys
      list.import_key(File.read(dir + 'pubring.gpg'))

      # Subscribe members
      YAML.load(File.read(dir + 'members.conf')).each do |member|
        list.subscribe(member['email'], member['fingerprint'])
      end

      # Subscribe or flag admins
      conf['admins'].each do |member|
        sub = list.subscriptions.where(email: member['email']).first
        if sub
          sub.admin = true
          sub.save!
        else
          adminfpr = member['fingerprint'] || list.keys(member['email']).first.fingerprint
          list.subscribe(member['email'], adminfpr, true)
        end
      end

      # Notify of removed options
      say "Please note: the following options have been *removed*:
* `default_mime` for lists (we only support pgp/mime for now),
* `archive` for lists,
* `gpg_passphrase` for lists,
* `log_file`, `log_io`, `log_syslog` for lists (we only log to
         syslog (before list-creation) and a file (after it) for now),
* `mime` for subscriptions/members (we only support pgp/mime for now),
* `send_encrypted_only` for members/subscriptions.

If you really miss any of them please tell us.

Please also note that the following keywords have been renamed:
* list-members  => list-subscriptions
* add-member    => subscribe
* delete-member => unsubscribe

Please notify the users and admins of this list of these changes.
"

      say "\nList #{listname} migrated to schleuder v3."
    rescue => exc
      fatal [exc, exc.backtrace.slice(0,2)].join("\n")
    end

    no_commands do
      def fatal(msg)
        error(msg)
        exit 1
      end

      KEYWORDS = {
        'add-member' => 'subscribe',
        'delete-member' => 'unsubscribe',
        'list-members' => 'list-subscriptions',
        'subscribe' => 'subscribe',
        'unsubscribe' => 'unsubscribe',
        'list-subscriptions' => 'list-subscriptions',
        'set-finterprint' => 'set-fingerprint',
        'add-key' => 'add-key',
        'delete-key' => 'delete-key',
        'list-keys' => 'list-keys',
        'get-key' => 'get-key',
        'fetch-key' => 'fetch-key'
      }

      def filter_keywords(value)
        Array(value).map do |keyword|
          KEYWORDS[keyword.downcase]
        end.compact
      end
    end
  end
end
