module Schleuder
  module Cli
    class Install < Thor
      default_task :install

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
end

