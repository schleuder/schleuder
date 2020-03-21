module Schleuder
  module KeywordHandlers
    class Resend < Base
      # TODO: specify regexp of wanted arguments or just the number of them
      handles_list_keyword 'resend-encrypted-only', with_method: :resend_encrypted_only, has_aliases: 'resend-enc', wanted_arguments: /\A([^ ]+@[[:alnum:]_.-]+\s?)+\z/i

      handles_list_keyword 'resend', with_method: :resend, wanted_arguments: /\A(#{Conf::EMAIL_REGEXP_EMBED}#{SEPARATORS}*)+\z/i

      handles_list_keyword 'resend-cc', with_method: :resend_cc, wanted_arguments: [Conf::EMAIL_REGEXP]

      handles_list_keyword 'resend-cc-encrypted-only', with_method: :resend_cc_encrypted_only, has_aliases: 'resend-cc-enc', wanted_arguments: [Conf::EMAIL_REGEXP]

      handles_list_keyword 'resend-unencrypted', with_method: :resend_unencrypted, wanted_arguments: [Conf::EMAIL_REGEXP]

      handles_list_keyword 'resend-cc-unencrypted', with_method: :resend_cc_unencrypted, wanted_arguments: [Conf::EMAIL_REGEXP]


      def resend
        resend_it
      end

      def resend_encrypted_only
        return if ! may_resend_encrypted?
        resend_it(encrypted_only: true)
      end

      def resend_cc
        resend_it_cc
      end

      def resend_cc_encrypted_only
        return if ! may_resend_encrypted?
        resend_it_cc(encrypted_only: true)
      end

      def resend_unencrypted
        do_resend_unencrypted(:to)
      end

      def resend_cc_unencrypted
        do_resend_unencrypted(:cc)
      end


      private


      def do_resend_unencrypted(target)
        return if ! may_resend_unencrypted?

        if ! resend_recipients_valid?
          return false
        end

        recip_map = Hash[Array(@arguments).map { |email| [email, ''] } ]

        if do_resend(recip_map, target, false)
          mail.add_subject_prefix_out!
        end
      end

      def resend_it_cc(encrypted_only: false)
        if ! resend_recipients_valid?
          return false
        end

        recip_map = map_with_keys(encrypted_only: encrypted_only)

        # Only continue if all recipients are still here.
        if recip_map.size < @arguments.size
          return
        end

        if recip_map.keys.size != @arguments.size
          return if ! may_resend_unencrypted?
        else
          return if ! may_resend_encrypted?
        end

        if do_resend(recip_map, :cc, encrypted_only)
          @mail.add_subject_prefix_out!
        end
      end

      def resend_it(encrypted_only: false)
        if ! resend_recipients_valid?
          return false
        end

        recip_map = map_with_keys(encrypted_only: encrypted_only)

        if recip_map.keys.size != @arguments.size
          return if ! may_resend_unencrypted?
        else
          return if ! may_resend_encrypted?
        end

        resent_stati = recip_map.map do |email, key|
          do_resend({email => key}, :to, encrypted_only)
        end

        if resent_stati.include?(true)
          # At least one message has been resent
          @mail.add_subject_prefix_out!
        end
      end

      def do_resend(recipients_map, to_or_cc, encrypted_only)
        if recipients_map.empty?
          return
        end

        gpg_opts = make_gpg_opts(recipients_map, encrypted_only)
        if gpg_opts == false
          return false
        end

        # Compose and send email
        new = @mail.clean_copy
        new[to_or_cc] = recipients_map.keys
        new.add_public_footer!
        new.sender = @list.bounce_address
        # `dup` gpg_opts because `deliver` changes their value and we need them
        # below to determine encryption!
        new.gpg gpg_opts.dup

        if new.deliver
          add_resent_headers(recipients_map, to_or_cc, gpg_opts[:encrypt])
          return true
        else
          add_error_header(recipients_map)
          return false
        end
      rescue Net::SMTPFatalError => exc
        add_error_header(recipients_map)
        logger.error "Error while sending: #{exc}"
        return false
      end

      def map_with_keys(encrypted_only:)
        Array(@arguments).inject({}) do |hash, email|
          keys = @list.keys(email)
          # Exclude unusable keys.
          keys.select! { |key| key.usable_for?(:encrypt) }
          case keys.size
          when 1
            hash[email] = keys.first
          when 0
            if encrypted_only
              # Don't add the email to the result to exclude it from the
              # recipients.
              add_keys_error(email, keys.size)
            else
              hash[email] = ''
            end
          else
            # Always report this situation, regardless of sending or not. It's
            # bad and should be fixed.
            add_keys_error(email, keys.size)
            if ! encrypted_only
              hash[email] = ''
            end
          end
          hash
        end
      end

      def make_gpg_opts(recipients_map, encrypted_only)
        gpg_opts = @list.gpg_sign_options
        # Do all recipients have a key?
        if recipients_map.values.map(&:class).uniq == [GPGME::Key]
          gpg_opts.merge!(encrypt: true)
        elsif encrypted_only
          false
        end
        gpg_opts
      end

      def add_keys_error(address, keys_size)
        @mail.add_pseudoheader(:error, I18n.t('keyword_handlers.resend.not_resent_no_keys', email: address, num_keys: keys_size))
      end

      def add_error_header(recipients_map)
        @mail.add_pseudoheader(:error, "Resending to #{recipients_map.keys.join(', ')} failed, please check the logs!")
      end

      def add_resent_headers(recipients_map, to_or_cc, sent_encrypted)
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
        @mail.add_pseudoheader(headername, "#{prefix} #{str}")
      end

      def resent_header_name(to_or_cc)
        if to_or_cc.to_s == 'to'
          'resent'
        else
          'resent_cc'
        end
      end

      def resend_recipients_valid?
        all_valid = true
        Array(@arguments).each do |address|
          if ! address.match(Conf::EMAIL_REGEXP)
            mail.add_pseudoheader(:error, I18n.t('keyword_handlers.resend.invalid_recipient', address: address))
            all_valid = false
          end
        end
        all_valid
      end

      def may_resend_encrypted?
        authorized_for?(:resend_encrypted)
      end

      def may_resend_unencrypted?
        authorized_for?(:resend_unencrypted)
      end

      def authorized_for?(action)
        authorize!(@list, action)
        return true
      rescue Errors::Unauthorized
        @mail.add_pseudoheader(:error, keyword_permission_error(:resend))
        return false
      end
    end
  end
end
