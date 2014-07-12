module Schleuder
  class Runner
    def initialize(msg, recipient)
      error = setup_list(recipient)
      if error
        return error
      end

      list.logger.debug "Parsing incoming email."
      begin
        # This decrypts, verifies, etc.
        @mail = Mail.new(msg).setup(recipient)
      rescue GPGME::Error::DecryptFailed => exc
        logger.warn "Decryption of incoming message failed.\nOriginal message:\n\n"
        return Errors::DecryptionFailed.new(list)
      end

      send_key if @mail.sendkey_request?
      forward_to_owner if @mail.to_owner?

      # TODO: implement receive_*
      if @mail.validly_signed?
        output = run_plugins

        if @mail.request?
          reply_to_sender(output)
        else
          send_to_subscriptions
        end
      else 
        if ! list.receive_signed_only?
          send_to_subscriptions
        else
          return Errors::MessageUnsigned.new(list)
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
      @mail.reply_to_sender(output).deliver
    end
    
    def send_to_subscriptions(subscriptions=nil)
      subscriptions ||= list.subscriptions
      new = @mail.clean_copy(list)
      subscriptions.each do |subscription|
        out = subscription.send_mail(new)
      end
    end

    def list
      @list
    end

    def run_plugins
      setup_plugins
      list.logger.debug "Running plugins"
      # TODO: move strings to locale-files
      output = []
      @mail.keywords.each do |keyword|
        if keyword_admin_only?(keyword) && ! mail_from_admin?
          # TODO: write error to metadata[:errors]?
          output << "Error: Use of '#{keyword}' is restricted to list-admins only."
          next
        end
        command = keyword.gsub('-', '_')
        if Plugin.respond_to?(command)
          begin 
            output << Plugin.send(command, @mail)
          rescue => exc
            # TODO: note the plugin-failure in meta-headers?
            logger.error(exc)
          end
        end
      end

      # Generate output to be sent back to the sender.
      if @mail.request?
        msg = ["Result of your commands:"]
        if output.empty?
          msg << "There was no output."
        else 
          msg += output
        end
      end
    end

    def keyword_admin_only?(keyword)
      list.keywords_admin_only.include?(keyword)
    end

    def mail_from_admin?
      return false unless @mail.validly_signed?
      list.admins.find do |admin|
        admin.fingerprint == @mail.signature.fingerprint
      end.presence || false
    end

    def logger
      list.present? && list.logger || Schleuder.logger
    end

    def setup_plugins
      list.logger.debug "Loading plugins"
      Dir["#{Conf.plugins_dir}/*.rb"].each do |file|
        require file
      end
    end

    def setup_list(recipient)
      return @list if @list

      logger.info "Loading list 'recipient'"
      if ! @list = List.by_recipient(recipient)
        logger.info 'List not found'
        return Errors::ListNotFound.new(recipient)
      end
      # This cannot be put in List, as Mail wouldn't know it then.
      ENV['GNUPGHOME'] = @list.listdir
      nil
    end

  end
end
