module Schleuder
  module Plugins
    def self.unsubscribe_self(arguments, list, mail)
      list.subscriptions.where(email: mail.signer.email).delete
    end

    def self.unsubscribe_me(*args)
      self.unsubscribe_self(*args)
    end

    # TODO: Better name for this
    def self.change_my_fingerprint(arguments, list, mail)
      list.subscriptions.where(email: mail.signer.email).update_attribute(:fingerprint, arguments.first)
    end
  end
end

