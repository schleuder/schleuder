module Schleuder
  module Filters

    def self.receive_encrypted_only(list, mail)
      if list.receive_encrypted_only? && ! mail.was_encrypted?
        Schleuder.logger.info "Rejecting mail as unencrypted"
        return Errors::MessageUnencrypted.new(list)
      end
    end

    def self.receive_signed_only(list, mail)
      if list.receive_signed_only? && ! mail.was_validly_signed?
        return Errors::MessageUnsigned.new(list)
      end
    end

    def self.receive_authenticated_only(list, mail)
      if list.receive_authenticated_only? && ( ! mail.was_encrypted? || ! mail.was_validly_signed? )
        return Errors::MessageUnauthenticated.new(list)
      end
    end

    def self.receive_from_subscribed_emailaddresses_only(list, mail)
      if list.receive_from_subscribed_emailaddresses_only? && Subscription.where(email: mail.from.first).blank?
        return Errors::MessageSenderNotSubscribed.new(list)
      end
    end

    def self.receive_admin_only(list, mail)
      if list.receive_admin_only? && ( ! mail.was_validly_signed? || ! mail.signer.admin? )
        return Errors::MessageNotFromAdmin.new(list)
      end
    end
  end
end


