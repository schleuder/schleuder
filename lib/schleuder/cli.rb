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
    def check_keys
      List.all.each do |list|
        I18n.locale = list.language

        text = list.check_keys

        if text && ! text.empty?
          msg = "#{I18n.t('check_keys_intro', email: list.email)}\n\n#{text}"
          list.logger.notify_admin(msg, nil, I18n.t('check_keys'))
        end
      end
    end

    desc 'refresh_keys [list1@example.com]', "Refresh all keys of all list from the keyservers sequentially (one by one or on the passed list). (This is supposed to be run from cron weekly.)"
    def refresh_keys(list=nil)
      work_on_lists(:refresh_keys,list)
    end

    desc 'pin_keys [list1@example.com]', "Find keys for subscriptions without a pinned key and try to pin a certain key (one by one or based on the passed list)."
    def pin_keys(list=nil)
      work_on_lists(:pin_keys,list)
    end

    desc 'install', "Set-up or update Schleuder environment (create folders, copy files, fill the database)."
    def install
      config_dir = Pathname.new(ENV['SCHLEUDER_CONFIG']).dirname
      root_dir = Pathname.new(ENV['SCHLEUDER_ROOT'])

      # Check if lists_dir contains v2-data.
      if Dir.glob("#{Conf.lists_dir}/*/*/members.conf").size > 0
        msg = "Lists directory #{Conf.lists_dir} appears to contain data from a Schleuder version 2.x installation.\nPlease move it out of the way or configure a different `lists_dir` in `#{ENV['SCHLEUDER_CONFIG']}`.\nTo migrate lists from Schleuder v2 to Schleuder v3 please use `schleuder migrate_v2_list` after the installation succeeded."
        fatal msg, 2
      end

      [Conf.lists_dir, Conf.listlogs_dir, config_dir, ENV['SCHLEUDER_RUN_STATE_DIR']].each do |dir|
        dir = Pathname.new(dir)
        if ! dir.exist?
          begin
            dir.mkpath
          rescue Errno::EACCES => exc
            problem_dir = exc.message.split(' - ').last
            fatal "Cannot create required directory due to lacking write permissions: #{problem_dir}.\nPlease fix the permissions or create the directory manually and then run this command again."
          end
        end
      end

      Pathname.glob(root_dir.join("etc").join("*.yml")).each do |file|
        target = config_dir.join(file.basename)
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
        if Conf.database['adapter'].match(/sqlite/)
          say "NOTE: The database was prepared using sqlite. If you prefer to use a different DBMS please edit the 'database'-section in /etc/schleuder/schleuder.yml, create the database, install the corresponding ruby-library (e.g. `gem install mysql`) and run this current command again"
        end
      end

      if ! File.exist?(Conf.api['tls_cert_file']) || ! File.exist?(Conf.api['tls_key_file'])
        Schleuder::Cert.new.generate
      end

      say "Schleuder has been set up. You can now create a new list using `schleuder-cli`.\nWe hope you enjoy!"
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
      listkey = GPGME::Key.find(:public, "<#{listname}>").first
      if listkey.nil?
        fatal "Failed to identify the list's OpenPGP-key!"
      end

      # Create list.
      begin
        list, messages = Schleuder::ListBuilder.new({email: listname, fingerprint: listkey.fingerprint}).run
      rescue => exc
        fatal exc
      end
      if messages
        fatal messages.values.join(" - ")
      elsif list.errors.any?
        fatal list.errors.full_messages.join(" - ")
      end

      # Import keys
      list.import_key(File.read(dir + 'pubring.gpg'))
      list.import_key(File.read(dir + 'secring.gpg'))

      # Clear passphrase of imported list-key.
      output = list.key.clearpassphrase(conf['gpg_password'])
      if output.present?
        fatal "while clearing passphrase of list-key: #{output.inspect}"
      end

      # Set list-options.
      List.configurable_attributes.each do |option|
        option = option.to_s
        if conf.keys.include?(option)
          value = case option
                  when /^keywords_/
                    filter_keywords(conf[option])
                  when 'log_level'
                    conf[option].to_s.downcase
                  else
                    conf[option]
                  end
          list.set_attribute(option, value)
        end
      end

      # Set changed options.
      changed_options = {
        'prefix' => 'subject_prefix',
        'prefix_in' => 'subject_prefix_in',
        'prefix_out' => 'subject_prefix_out',
        'dump_incoming_mail' => 'forward_all_incoming_to_admins',
        'receive_from_member_emailaddresses_only' => 'receive_from_subscribed_emailaddresses_only',
        'bounces_notify_admin' => 'bounces_notify_admins',
        'max_message_size' => 'max_message_size_kb'
      }

      changed_options.each do |old, new|
        if conf.keys.include?(old)
          list.set_attribute(new, conf[old])
        end
      end
      list.save!

      # Subscribe members
      members = YAML.load(File.read(dir + 'members.conf'))
      members.uniq!{|m| m['email'] }
      members.each do |member|
        fingerprint = find_fingerprint(member, list)
        list.subscribe(member['email'], fingerprint)
      end

      # Subscribe or flag admins
      conf['admins'].each do |member|
        sub = list.subscriptions.where(email: member['email']).first
        if sub
          sub.admin = true
          sub.save!
        else
          adminfpr = find_fingerprint(member, list)
          # if we didn't find an already imported  subscription for the admin
          # address, it wasn't a member, so we don't enable delivery for it
          list.subscribe(member['email'], adminfpr, true, false)
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
      fatal "#{exc}\n#{exc.backtrace.first}"
    end

    no_commands do
      def fatal(msg, exitcode=1)
        error("Error: #{msg}")
        exit exitcode
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

      def find_fingerprint(member, list)
        email = member['email']
        fingerprint = member['key_fingerprint']
        if fingerprint.present?
          return fingerprint
        end

        key = list.distinct_key(email)
        if key
          return key.fingerprint
        else
          return nil
        end
      end
    end
    private
    def work_on_lists(subj, list=nil)
      selected_lists = if list.nil?
        List.all
      else
        List.where(email: list)
      end
      selected_lists.each do |list|
        I18n.locale = list.language
        output = list.send(subj)
        if output.present?
          msg = "#{I18n.t("#{subj}_intro", email: list.email)}\n\n#{output}"
          list.logger.notify_admin(msg, nil, I18n.t(subj))
        end
      end
    end

  end
end
