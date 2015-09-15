module Schleuder
  module Cli
    class Subscription < Thor
      include Helper
      extend SubcommandFix

      desc 'new list@hostname user@example.org [fingerprint] [/path/to/public.key]', 'Subscribe an email-address to a list.'
      def new(listname, email, fingerprint = nil, keyfile = nil)
        fatal "Not implemented"
      end

      desc 'configure list@hostname user@hostname option [value]', 'Get or set the value of a subscription-option'
      def configure(listname, email, option=nil, value=nil)
        list = getlist(listname)
        subscription = getsubscription(list, email)
        show_or_set_config(subscription, option, value)
      end
    
      desc 'delete list@hostname user@example.org [fingerprint]', 'Unsubscribe user@example.org from list@hostname (and delete public key if fingerprint is given)'
      def delete(listname, email, fingerprint = nil)
        list = getlist(listname)
        subscription = getsubscription(list, email)
        if subscription.destroy
          say "#{email} unsubscribed."
        else
          fatal "Deleting failed: #{subscription.errors.inspect}"
        end

        if fingerprint.present?
          # TODO: use gpgme
          say "Deleteing key from keyring: "
          say `gpg --homedir "#{list.listdir}" --batch --delete-key "#{keyfile}"`
        end

      end


      no_commands do
        def getsubscription(list, email)
          subscription = Schleuder::Subscription.where(list: list, email: email).first
          if subscription.blank?
            fatal "Address not subscribed to list."
          end
          subscription
        end
      end

    end
  end
end
