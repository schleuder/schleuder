module Schleuder
  module Filters
    def self.key_auto_import_from_attachments(list, mail)
      # Don't run if not enabled.
      return if ! list.key_auto_import_from_email

      imported_fingerprints = EmailKeyImporter.import_from_attachments(list, mail)
      if imported_fingerprints.size > 0
        # If the message's signature could not be validated before, re-run the
        # validation, because after having imported new or updated keys the
        # validation now might work.
        if mail.signature.present? && ! mail.signature.valid?
          # Re-validate the signature validation, now that a new key was
          # imported that might be the previously unknown signing key.
          mail.repeat_validation!
        end
      end
    end
  end
end

