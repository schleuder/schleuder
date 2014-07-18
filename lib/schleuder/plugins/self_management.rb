module Schleuder
  module Plugins
    def self.unsubscribe_me(arguments, list, mail)
      list.subscriptions.where(email: mail.signer.email).delete
    end
    alias_method :unsubscribe_self, :unsubscribe_me

    # TODO: Better name for this
    def self.change_my_fingerprint(arguments, list, mail)
      list.subscriptions.where(email: mail.signer.email).update_attribute(:fingerprint, arguments)
    end
  end
end

