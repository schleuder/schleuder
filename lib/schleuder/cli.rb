require 'thor'
require 'yaml'
require 'gpgme'

require_relative '../schleuder'
require 'schleuder/cli/subcommand_fix'
require 'schleuder/cli/schleuder_cert_manager'
require 'schleuder/cli/cert'

module Schleuder
  class Cli < Thor

    register(Cert,
             'cert',
             'cert ...',
             'Generate TLS-certificate and show fingerprint')

    map '-v' => :version
    map '--version' => :version
    desc 'version', 'Show version of schleuder'
    def version
      say Schleuder::VERSION
    end

    desc 'new_api_key', 'Generate a new API key to be used by a client.'
    def new_api_key
      require 'securerandom'
      puts SecureRandom.hex(32)
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
        Schleuder.logger.fatal(exc.message_with_backtrace, message)
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

    desc 'install', "Set-up or update Schleuder environment (create folders, copy files, fill the database)."
    def install
      %w[/var/schleuder/lists /etc/schleuder].each do |dir|
        dir = Pathname.new(dir)
        if ! dir.exist?
          if dir.dirname.writable?
            dir.mkpath
          else
            fatal "Cannot create required directory due to lacking write permissions, please create manually and then run this command again:\n#{dir}"
          end
        end
      end

      Pathname.glob(Pathname.new(root_dir).join("etc").join("*.yml")).each do |file|
        target = Pathname.new("/etc/schleuder/").join(file.basename)
        if ! target.exist?
          if target.dirname.writable?
            FileUtils.cp file, target
          else
            fatal "Cannot copy default config file due to lacking write permissions, please copy manually and then run this command again:\n#{file.realpath} → #{target}"
          end
        end
      end

      if ActiveRecord::SchemaMigration.table_exists?
        say `cd #{root_dir} && rake db:migrate`
      else
        say `cd #{root_dir} && rake db:schema:load`
        say "NOTE: The database was prepared using sqlite. If you prefer to use a different DBMS please edit the 'database'-section in /etc/schleuder/schleuder.yml, create the database, install the corresponding ruby-library (e.g. `gem install mysql`) and run this current command again"
      end

      say "Schleuder has been set up. You can now create a new list using `schleuder-conf`.\nWe hope you enjoy!"
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
      # TODO: Check for errors!
      list, messages = Schleuder::ListBuilder.new({email: listname, fingerprint: fingerprint}).run

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
      if messages.present?
        say messages.gsub(' // ', "\n")
      end
    rescue => exc
      fatal [exc, exc.backtrace.slice(0,2)].join("\n")
    end

    no_commands do
      def fatal(msg)
        error("Error: #{msg}")
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

      def root_dir
        Pathname.new(__FILE__).dirname.dirname.dirname.realpath
      end
    end
  end
end
