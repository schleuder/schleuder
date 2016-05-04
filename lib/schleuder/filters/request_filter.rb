module Schleuder
  module Filters
    def self.request(list, mail)
      return if ! mail.request?

      list.logger.debug "Request-message"
      if ! mail.was_encrypted_mime?
        list.logger.debug "Error: Message is not pgp/mime-encrypted."
        return Errors::NotPgpMime.new
      end

      if ! mail.was_encrypted? || ! mail.was_validly_signed?
        list.logger.debug "Error: Message was not encrypted and validly signed"
        return Errors::MessageUnauthenticated.new
      end

      if mail.keywords.empty?
        output = I18n.t(:no_keywords_error)
      else
        output = Plugins::Runner.run(list, mail).compact
      end
      mail.reply_to_signer(output)
      exit
    end
  end
end
