module Schleuder
  module Filters
    def self.auto_import_key_from_servers(list, mail)
      #return if ! list.auto_import_key_from_servers
      # Only work on signed emails for which the signing key isn't present.
      return if mail.signature.blank? || mail.signing_key.present?
      # TODO: also look for key if encrypted but not signed
      repeat_verification = true

      result = KeyFetcher.fetch(mail.signature.fingerprint, "auto_import_key_from_servers")
      if result.is_a?(StandardError)
        mail.add_pseudoheader(:note, result.to_s)
        # TODO: only actually import if the key we found by email address is the actual signing key?
        result = KeyFetcher.fetch(mail.from.addresses.first, "auto_import_key_from_servers")
        if result.is_a?(StandardError)
          mail.add_pseudoheader(:note, result.to_s)
          repeat_verification = false
        end
      end

      if repeat_verification
        mail.add_pseudoheader(:note, result.to_s)
        new_mail = mail.original_message.setup
        mail.verify_result = new_mail.verify_result
      end
    rescue StandardError => exc
      msg = "Error in auto_import_key_from_servers: #{exc}"
      mail.add_pseudoheader(:error, result.to_s)
      list.logger.error(msg)
    end
  end
end
