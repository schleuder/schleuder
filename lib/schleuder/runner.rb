module Schleuder
  class Runner
    def run(msg, recipient)
      error = setup_list(recipient)
      if error
        return error
      end

      list.logger.info "Parsing incoming email."
      begin
        # This decrypts, verifies, etc.
        @mail = Mail.new(msg)
        @mail = @mail.setup(recipient)
      rescue GPGME::Error::DecryptFailed => exc
        logger.warn "Decryption of incoming message failed."
        return Errors::DecryptionFailed.new(list)
      end

      send_key if @mail.sendkey_request?
      forward_to_owner if @mail.to_owner?

      # TODO: implement receive_*
      if @mail.was_encrypted? && @mail.was_validly_signed?
        output = Plugins::Runner.run(list, @mail).compact

        if @mail.request?
          reply_to_sender(output)
        else
          # Any output will be treated as error. Text meant for users should
          # have been put into the mail by the plugin.
          output.each do |something|
            @mail.add_pseudoheader(:error, something.to_s)
          end
          send_to_subscriptions
        end
      else
        if list.receive_signed_only?
          return Errors::MessageUnsigned.new(list)
        else
          send_to_subscriptions
        end
      end
      nil
    end

    private

    def forward_to_owner
      send_to_subscriptions(list.admins)
      exit
    end

    def send_key
      list.logger.debug "Sending public key as reply."
      @mail.reply_sendkey(list).deliver
      exit
    end

    def reply_to_sender(output)
      if output.empty?
        msg = I18n.t('no_output_result')
      else
        msg = [ I18n.t('output_result_prefix'),
                output.map(&:to_s) ].flatten.join("\n\n")
      end
      @mail.reply_to_sender(msg).deliver
    end

    def send_to_subscriptions(subscriptions=nil)
      subscriptions ||= list.subscriptions
      new = @mail.clean_copy(list, true)
      subscriptions.each do |subscription|
        out = subscription.send_mail(new)
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
      ENV['GNUPGHOME'] = @list.listdir
      nil
    end

  end
end
