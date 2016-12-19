module Schleuder
  module ListPlugins
    def self.resend(arguments, list, mail)
      resend_it(arguments, mail, false)
    end

    def self.resend_enc(arguments, list, mail)
      resend_encrypted_only(arguments, list, mail)
    end

    def self.resend_encrypted_only(arguments, list, mail)
      resend_it(arguments, mail, true)
    end

    def self.resend_cc(arguments, list, mail)
      resend_it_cc(arguments, mail, false)
    end

    def self.resend_cc_enc(arguments, list, mail)
      resend_cc_encrypted_only(arguments, list, mail)
    end

    def self.resend_cc_encrypted_only(arguments, list, mail)
      resend_it_cc(arguments, mail, true)
    end

    def self.resend_it_cc(arguments, mail, encrypted_only)
      recip_map = map_with_keys(mail, arguments, encrypted_only)

      # Only continue if all recipients are still here.
      if recip_map.size < arguments.size
        return
      end

      if do_resend(mail, recip_map, :cc, encrypted_only)
        mail.add_subject_prefix_out!
      end

      # Return nil to prevent any accidental output to be interpreted as an
      # error.
      nil
    end

    def self.resend_it(arguments, mail, encrypted_only)
      recip_map = map_with_keys(mail, arguments, encrypted_only)

      resent_stati = recip_map.map do |email, key|
        do_resend(mail, {email => key}, :to, encrypted_only)
      end

      if resent_stati.include?(true)
        # At least one message has been resent
        mail.add_subject_prefix_out!
      end

      # Return nil to prevent any accidental output to be interpreted as an
      # error.
      nil
    end

    def self.do_resend(mail, recipients_map, to_or_cc, encrypted_only)
      if recipients_map.empty?
        return
      end

      gpg_opts = make_gpg_opts(mail, recipients_map, encrypted_only)
      if gpg_opts == false
        return false
      end

      # Compose and send email
      new = mail.clean_copy
      new[to_or_cc] = recipients_map.keys
      new.add_footer!
      # `dup` gpg_opts because `deliver` changes their value and we need them
      # below to determine encryption!
      new.gpg gpg_opts.dup

      if new.deliver
        add_resent_headers(mail, recipients_map, to_or_cc, gpg_opts[:encrypt])
        return true
      else
        add_error_header(mail, recipients_map)
        return false
      end
    rescue Net::SMTPFatalError => exc
      add_error_header(mail, recipients_map)
      logger.error "Error while sending: #{exc}"
      return false
    end

    def self.map_with_keys(mail, recipients, encrypted_only)
      Array(recipients).inject({}) do |hash, email|
        keys = mail.list.keys_by_email(email)
        case keys.size
        when 1
          hash[email] = keys.first
        when 0
          if encrypted_only
            # Don't add the email to the result to exclude it from the
            # recipients.
            add_keys_error(mail, email, keys.size)
          else
            hash[email] = ''
          end
        else
          # Always report this situation, regardless of sending or not. It's
          # bad and should be fixed.
          add_keys_error(mail, email, keys.size)
          if ! encrypted_only
            hash[email] = ''
          end
        end
        hash
      end
    end

    def self.make_gpg_opts(mail, recipients_map, encrypted_only)
      gpg_opts = mail.list.gpg_sign_options
      # Do all recipients have a key?
      if recipients_map.values.map(&:class).uniq == [GPGME::Key]
        gpg_opts.merge!(encrypt: true)
      elsif encrypted_only
        false
      end
      gpg_opts
    end

    def self.add_keys_error(mail, email, keys_size)
      mail.add_pseudoheader(:error, I18n.t("plugins.resend.not_resent_no_keys", email: email, num_keys: keys_size))
    end

    def self.add_error_header(mail, recipients_map)
      mail.add_pseudoheader(:error, "Resending to #{recipients_map.keys.join(', ')} failed, please check the logs!")
    end

    def self.add_resent_headers(mail, recipients_map, to_or_cc, sent_encrypted)
      if sent_encrypted
        prefix = I18n.t('plugins.resend.encrypted_to')
        str = recipients_map.map do |email, key|
          "#{email} (#{key.fingerprint})"
        end.join(', ')
      else
        prefix = I18n.t('plugins.resend.unencrypted_to')
        str = recipients_map.keys.join(', ')
      end
      headername = resent_header_name(to_or_cc)
      mail.add_pseudoheader(headername, "#{prefix} #{str}")
    end

    def self.resent_header_name(to_or_cc)
      if to_or_cc.to_s == 'to'
        'resent'
      else
        'resent_cc'
      end
    end
  end
end
