require 'thor'

module Schleuder
  class Cli < Thor

    desc 'version', 'Show version of schleuder'
    def version
      say Schleuder::VERSION
    end

    desc 'work list@hostname < message', 'Run a message through a list.'
    def work(listname)
      require_relative '../schleuder'

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
      require_relative '../schleuder'

      Schleuder::List.all.each do |list|
        I18n.locale = list.language

        text = list.check_keys

        if text.present?
          msg = "#{I18n.t('check_keys_intro', email: list.email)}\n\n#{text}"
          list.logger.notify_admin(msg, nil, I18n.t('check_keys'))
        end
      end
    end

    desc 'install', "Set up Schleuder initially. Create folders, copy files, fill the database, etc."
    def install
      if `id -u`.to_i > 0
        fatal "root-privileges required"
      end

      if ARGV.first == '--gem'
        spec = Gem::Specification.find_by_name('schleuder')
        path = spec.gem_dir
      else
        if ! File.directory?(ARGV.first)
          fatal "No such directory '#{ARGV.first}'"
        end
        path = ARGV.first
      end

      if ARGV.last != '--step2'
        FileUtils.mkdir_p %w[/var/schleuder /var/schleuder/lists /etc/schleuder]
        Dir[File.join(path, "etc/*")].each do |file|
          target = "/etc/schleuder/#{File.basename(file)}"
          if ! File.exists?(target)
            FileUtils.cp file, target
          end
        end
        say "Please adapt /etc/schleuder/schleuder.yml to your needs. If you choose a different DBMS than sqlite (e.g. mysql, postgresql) don't forget to create the database you configured and install the ruby-bindings (e.g. `gem install mysql`). Then run step 2: `#{$0} #{ARGV.join(' ')} --step2`"

      else

        # Step 2
        say "Step 2: Preparing the database."
        answer = ask "Ready? [yN] "
        if answer.downcase != 'y'
          say "Cancelled."
          exit
        end

        say `cd #{path} && rake db:schema:load`

        say "
        Schleuder has been set up. You can now create a new list using schleuder-newlist.
        We hope you enjoy!"
      end
    rescue => exc
      fatal exc.message
    end

  end
end
