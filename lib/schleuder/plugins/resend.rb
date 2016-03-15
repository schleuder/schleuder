module Schleuder
  module ListPlugins
    def self.resend(arguments, list, mail)
      resend_it(arguments, list, mail, false)
      # Return nil to prevent any erronous output to be interpreted as error.
      nil
    end

    def self.resend_encrypted_only(arguments, list, mail)
      resend_it(arguments, list, mail, true)
      nil
    end

    def self.resend_it(arguments, list, mail, send_encrypted_only)
      # If we must encrypt, first test if there's a key for every recipient.
      found_keys = {}
      arguments.each do |email|
        keys = list.keys(email)
        case keys.size
        when 0
          # TODO: I18n.
          mail.add_pseudoheader(:note, "No key found for #{email}.")
        when 1
          found_keys[email] = keys.first
        else
          # TODO: I18n.
          mail.add_pseudoheader(:note, "Multiple keys found for #{email}, not using any.")
        end
      end

      if send_encrypted_only
        missing = arguments.keys - found_keys.keys
        if missing.present?
          return I18n.t("plugins.resend.not_resent_no_keys", emails: missing.join(', '))
        end
      end

      arguments.map do |email|
        # Setup encryption
        gpg_opts = {sign: true}
        if found_keys[email].present?
          gpg_opts.merge!(encrypt: true)
        end

        # Compose and send email
        new = mail.clean_copy(list)
        new.to = email

        # Add public_footer unless it's empty?.
        if ! list.public_footer.to_s.strip.empty?
          footer_part = Mail::Part.new
          footer_part.body = list.public_footer.strip
          new.add_part footer_part
        end

        new.gpg gpg_opts
        if new.deliver
          mail.add_pseudoheader('resent-to', resent_pseudoheader(email, found_keys[email]))
          mail.add_subject_prefix(list.subject_prefix_out)
        end
      end
      # TODO: catch and handle SMTPFatalError (is raised when recipient is rejected by remote)
    end

    def self.resent_pseudoheader(email, key)
      str = email
      if key.present?
        str << " (#{I18n.t('plugins.resend.encrypted_with')} #{key.fingerprint})"
      else
        str << " (#{I18n.t('plugins.resend.unencrypted')})"
      end
    end
  end
end
