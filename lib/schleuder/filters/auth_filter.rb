module Schleuder
  module Filters

    def self.receive_encrypted_only(list, mail)
      if list.receive_encrypted_only? && ! mail.was_encrypted?
        list.logger.info "Rejecting mail as unencrypted"
        return Errors::MessageUnencrypted.new
      end
    end

    def self.receive_signed_only(list, mail)
      if list.receive_signed_only? && ! mail.was_validly_signed?
        list.logger.info "Rejecting mail as unsigned"
        return Errors::MessageUnsigned.new
      end
    end

    def self.receive_authenticated_only(list, mail)
      if list.receive_authenticated_only? && ( ! mail.was_encrypted? || ! mail.was_validly_signed? )
        list.logger.info "Rejecting mail as unauthenticated"
        return Errors::MessageUnauthenticated.new
      end
    end

    def self.receive_from_subscribed_emailaddresses_only(list, mail)
      if list.receive_from_subscribed_emailaddresses_only? && list.subscriptions.where(email: mail.from.first).blank?
        list.logger.info "Rejecting mail as not from subscribed address."
        return Errors::MessageSenderNotSubscribed.new
      end
    end

    def self.receive_admin_only(list, mail)
      if list.receive_admin_only? && ( ! mail.was_validly_signed? || ! mail.signer.admin? )
        list.logger.info "Rejecting mail as not from admin."
        return Errors::MessageNotFromAdmin.new
      end
    end
  end
end
