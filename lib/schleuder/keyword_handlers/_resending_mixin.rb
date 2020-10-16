module Schleuder
  module KeywordHandlers
    module ResendingMixin
      ONE_OR_MANY_EMAIL_ADDRS = [Conf::EMAIL_REGEXP, Array.new(99, /(#{Conf::EMAIL_REGEXP_EMBED})?/)].flatten

      def do_resend_unencrypted(mail:, to_or_cc:)
        return if ! may_resend_unencrypted?(mail)

        if ! resend_recipients_valid?(mail)
          return false
        end

        recip_map = Hash[Array(@arguments).map { |email| [email, ''] } ]

        if do_resend(mail, recip_map, to_or_cc, false)
          mail.add_subject_prefix_out!
        end
      end

      def resend_it_cc(mail:, encrypted_only:)
        if ! resend_recipients_valid?(mail)
          return false
        end

        recip_map = map_with_keys(mail, encrypted_only)

        # Only continue if all recipients are still here.
        if recip_map.size < @arguments.size
          return
        end

        if recip_map.keys.size != @arguments.size
          return if ! may_resend_unencrypted?(mail)
        else
          return if ! may_resend_encrypted?(mail)
        end

        if do_resend(mail, recip_map, :cc, encrypted_only)
          mail.add_subject_prefix_out!
        end
      end

      def resend_it(mail:, encrypted_only:)
        if ! resend_recipients_valid?(mail)
          return false
        end

        recip_map = map_with_keys(mail, encrypted_only)

        if recip_map.keys.size != @arguments.size
          return if ! may_resend_unencrypted?
        else
          return if ! may_resend_encrypted?(mail)
        end

        resent_stati = recip_map.map do |email, key|
          do_resend(mail, {email => key}, :to, encrypted_only)
        end

        if resent_stati.include?(true)
          # At least one message has been resent
          mail.add_subject_prefix_out!
        end
      end

      def do_resend(mail, recipients_map, to_or_cc, encrypted_only)
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
        new.add_public_footer!
        new.sender = mail.list.bounce_address
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

      def map_with_keys(mail, encrypted_only)
        Array(@arguments).inject({}) do |hash, email|
          keys = mail.list.keys(email)
          # Exclude unusable keys.
          keys.select! { |key| key.usable_for?(:encrypt) }
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

      def make_gpg_opts(mail, recipients_map, encrypted_only)
        gpg_opts = mail.list.gpg_sign_options
        # Do all recipients have a key?
        if recipients_map.values.map(&:class).uniq == [GPGME::Key]
          gpg_opts.merge!(encrypt: true)
        elsif encrypted_only
          false
        end
        gpg_opts
      end

      def add_keys_error(mail, address, keys_size)
        mail.add_pseudoheader(:error, I18n.t('keyword_handlers.resend.not_resent_no_keys', email: address, num_keys: keys_size))
      end

      def add_error_header(mail, recipients_map)
        mail.add_pseudoheader(:error, "Resending to #{recipients_map.keys.join(', ')} failed, please check the logs!")
      end

      def add_resent_headers(mail, recipients_map, to_or_cc, sent_encrypted)
        if sent_encrypted
          prefix = I18n.t('keyword_handlers.resend.encrypted_to')
          str = recipients_map.map do |email, key|
            "#{email} (#{key.fingerprint})"
          end.join(', ')
        else
          prefix = I18n.t('keyword_handlers.resend.unencrypted_to')
          str = recipients_map.keys.join(', ')
        end
        headername = resent_header_name(to_or_cc)
        mail.add_pseudoheader(headername, "#{prefix} #{str}")
      end

      def resent_header_name(to_or_cc)
        if to_or_cc.to_s == 'to'
          'resent'
        else
          'resent_cc'
        end
      end

      def resend_recipients_valid?(mail)
        all_valid = true
        Array(@arguments).each do |address|
          if ! address.match(Conf::EMAIL_REGEXP)
            mail.add_pseudoheader(:error, I18n.t('keyword_handlers.resend.invalid_recipient', address: address))
            all_valid = false
          end
        end
        all_valid
      end

      def may_resend_encrypted?(mail)
        authorized_for?(mail, :resend_encrypted)
      end

      def may_resend_unencrypted?(mail)
        authorized_for?(mail, :resend_unencrypted)
      end

      def authorized_for?(mail, action)
        authorize!(mail.list, action)
        return true
      rescue Errors::Unauthorized
        mail.add_pseudoheader(:error, keyword_permission_error(:resend))
        return false
      end

    end
  end
end
