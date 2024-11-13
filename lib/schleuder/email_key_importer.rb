module Schleuder
  class EmailKeyImporter
    class << self
      def import_from_attachments(list, mail)
        # Shouldn't happen, but who knows...
        return if ! mail.from.first.match(Conf::EMAIL_REGEXP)
        mail.attachments.map do |part|
          if part.content_type == 'application/pgp-keys'
            filter_and_maybe_import_keys(mail, part.body.decoded)
          end
        end.compact
      end

      def import_from_autocrypt_header(list, mail)
        # Shouldn't happen, but who knows...
        return if ! mail.from.first.match(Conf::EMAIL_REGEXP)
        return if mail.header['Autocrypt'].blank?
        keydata_base64 = mail.header['Autocrypt'].to_s.split('keydata=', 2)[1]
        return if keydata_base64.blank?
        keydata = Base64.decode64(keydata_base64)
        return if keydata.blank?
        filter_and_maybe_import_keys(mail, keydata)
      end

      def filter_and_maybe_import_keys(mail, keydata)
        extracted_keys = GPGME::KeyExtractor.extract_by_email_address(mail.from.first, keydata)
        extracted_keys.map do |fingerprint, filtered_keydata|
          maybe_import_key(mail, fingerprint, filtered_keydata)
        end.compact
      end

      def maybe_import_key(mail, fingerprint, filtered_keydata)
        if mail.list.keys(fingerprint).size == 1
          return update_key(mail, filtered_keydata)
        end

        if mail.list.keys(mail.from.first).size > 0
          mail.add_pseudoheader('Note', I18n.t('email_key_importer.key_already_present'))
          return
        end
        add_key(mail, filtered_keydata)
      end

      def add_key(mail, keydata)
        fingerprint, import_states = import_to_list(mail, keydata)
        return if ! fingerprint
        if ! import_states.include?(I18n.t('import_states.new_key'))
          mail.list.logger.error "Importing key failed! Fingerprint: #{fingerprint.inspect} -- Import-states: #{import_states.inspect}"
          mail.add_pseudoheader('Note',
                                I18n.t('email_key_importer.import_error',
                                       fingerprint: fingerprint.inspect,
                                       import_states: import_states.inspect))
          return
        end
        key = mail.list.keys(fingerprint).first
        mail.add_pseudoheader('Note', I18n.t('email_key_importer.key_added',
                                             key_summary: key.summary))
        fingerprint
      end

      def update_key(mail, keydata)
        fingerprint, import_states = import_to_list(mail, keydata)
        return if ! fingerprint
        key = mail.list.keys(fingerprint).first
        if import_states == ['unchanged']
          mail.add_pseudoheader('Note',
                                I18n.t('email_key_importer.key_unchanged',
                                       key_summary: key.summary))
          return
        end

        key = mail.list.keys(fingerprint).first
        mail.add_pseudoheader('Note', I18n.t('email_key_importer.key_updated',
                                             key_summary: key.summary))
        fingerprint
      end

      def import_to_list(mail, keydata)
        result = mail.list.gpg.import_filtered(keydata)
        # At this point we expect the keydata to only contain one key, and thus
        # only one key and value in the result.
        if ! result.is_a?(Hash) || result.keys.size != 1 || ! result.values.first.is_a?(Array)
          mail.list.logger.error "Unexpected result when importing key from temporary keyring => #{result.inspect}"
          mail.add_pseudoheader('Note', I18n.t('email_key_importer.technical_error'))
          return false
        end
        [result.keys.first, result.values.first]
      end
    end
  end
end
