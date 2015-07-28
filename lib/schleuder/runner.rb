module Schleuder
  class Runner
    def run(msg, recipient)
      error = setup_list(recipient)
      return error if error

      list.logger.info "Parsing incoming email."
      begin
        # This decrypts, verifies, etc.
        @mail = Mail.new(msg)
        @mail = @mail.setup(recipient)
      rescue GPGME::Error::DecryptFailed
        logger.warn "Decryption of incoming message failed."
        return Errors::DecryptionFailed.new(list)
      end

      # Filters
      error = Filters::Runner.run(list, @mail)
      if error
        if list.bounces_notify_admins?
          # TODO: Improve with nicer message
          list.logger.notify_admin error.to_s, @mail
        end
        return error 
      end

      # Plugins
      if @mail.was_encrypted? && @mail.was_validly_signed?
        output = Plugins::Runner.run(list, @mail).compact

        if @mail.request?
          list.logger.debug "Request-message, replying with output"
          reply_to_signer(output)
          return nil
        else
          # Any output will be treated as error-message. Text meant for users
          # should have been put into the mail by the plugin.
          output.each do |something|
            @mail.add_pseudoheader(:error, something.to_s) if something.present?
          end

          # Don't send empty messages over the list.
          if @mail.body.empty?
            Schleuder.logger.info "Message found empty, not sending it to list. Instead notifying sender."
            reply_to_signer(I18n.t(:empty_message_error, request_address: @list.request_address))
            return nil
          end
        end
      end

      # TODO: implement attach_incoming

      # Subscriptions
      send_to_subscriptions
      nil
    end

    private

    def reply_to_signer(output)
      msg = output.presence || I18n.t('no_output_result')
      @mail.reply_to_signer(msg).deliver
    end

    def send_to_subscriptions
      new = @mail.clean_copy(list, true)
      list.subscriptions.each do |subscription|
        begin
          Schleuder.logger.debug "Sending message to #{subscription.inspect}"
          subscription.send_mail(new).deliver
        rescue => exc
          Schleuder.logger.error exc
        end
      end
    end

    def list
      @list
    end

    def logger
      list.present? && list.logger || Schleuder.logger
    end

    def setup_list(recipient)
      return @list if @list

      logger.info "Loading list '#{recipient}'"
      if ! @list = List.by_recipient(recipient)
        logger.info 'List not found'
        return Errors::ListNotFound.new(recipient)
      end

      # TODO: check sanity of list: admins, fingerprint, key, all present?

      # This cannot be put in List, as Mail wouldn't know it then.
      Schleuder.logger.debug "Setting GNUPGHOME to #{@list.listdir}"
      ENV['GNUPGHOME'] = @list.listdir
      nil
    end

  end
end
