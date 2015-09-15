module Schleuder
  module Cli
    class List < Thor
      include Helper
      extend SubcommandFix


      desc 'new list@hostname adminaddress [/path/to/publickeys.asc]', 'Create a new schleuder list.'
      def new(listname, adminaddress, adminkeypath)
        errors, list = ListBuilder.new(listname, adminaddress, adminkeypath).run
        if errors.present?
          error errors
          exit 1
        end

        say "List #{list.email} successfully created, #{adminaddress} subscribed!\nDon't forget to hook it into your MTA."
      end

      desc 'configure list@hostname option [value]', 'Get or set the value of a list-option.'
      def configure(listname, option=nil, value=nil)
        list = getlist(listname)
        show_or_set_config(list, option, value)
      end

      desc 'delete list@hostname', 'Delete the list.'
      def delete(listname)
        list = getlist(listname)
        if ! list.destroy
          fatal "Deleting failed: #{list.errors.inspect}"
        else
          say "List #{list.email} deleted from database."
        end

        answer = ask "Delete list-directory (#{list.listdir}), too? [yN] "
        if answer.downcase == 'y'
          if res = FileUtils.rm_r(list.listdir, secure: true)
            say "Done."
          else
            fatal "An unexpected error occurred! Result of deletion: #{res.inspect}"
          end
        end
      end

      desc 'importkey list@hostname /path/to/public.key', "Import OpenPGP-key-material into the list's keyring."
      def import_key(listname, keyfile)
        if ! File.readable?(keyfile)
          fatal "File '#{keyfile}' not readable"
        end
        list = getlist(listname)

        # TODO: use gpgme
        say "Importing key-file: "
        say `gpg --homedir "#{list.listdir}" --import "#{keyfile}"`
      end

      desc 'subscriptions list@hostname', 'List subscriptions to list.'
      def subscriptions(listname)
        list = getlist(listname)

        say list.subscriptions.map do |subscription|
          "#{subscription.email}\t#{subscription.fingerprint.presence || 'N/A'}"
        end.join("\n")

      end

    end
  end
end

