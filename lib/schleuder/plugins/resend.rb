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
      arguments.map do |email|
        # Setup encryption
        gpg_opts = {sign: true}
        key = list.keys(email)
        if key.present?
          gpg_opts.merge!(encrypt: true)
        elsif send_encrypted_only
          # TODO: rather send a note to the sender that the command failed. Chances are high that he/she will try again anyways and other subscribers don't need to see the noise.
          mail.add_pseudoheader(
            :note,
            I18n.t("plugins.resend.not_resent_no_key", email: email)
          )
          next
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
          mail.add_pseudoheader('resent-to', resent_pseudoheader(email, key))
          mail.add_subject_prefix(list.subject_prefix_out)
        end
      end
      # TODO: catch and handle SMTPFatalError (is raised when recipient is rejected by remote)
    end

    def self.resent_pseudoheader(email, key)
      str = email
      if key.present?
        str << " (#{I18n.t('plugins.resend.encrypted_with')} #{key.fpr})"
      else
        str << " (#{I18n.t('plugins.resend.unencrypted')})"
      end
    end
  end
end
