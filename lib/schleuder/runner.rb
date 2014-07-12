module Schleuder
  class Runner
    def initialize(msg, recipient)
      setup_list(recipient)
      list.logger.debug "Parsing incoming email."
      @mail = Mail.new(msg)

      begin
        # This decrypts, verifies, etc.
        @mail = @mail.setup recipient
      rescue GPGME::Error::DecryptFailed => exc
        error(:decrypt_failed, key_str: list.key.to_s)
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
          error(:msg_must_be_signed)
        end
      end
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
          output << Plugin.send(command, @mail)
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
    rescue => exc
      error(exc)
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

    def error(msg, args={})
      if msg.is_a?(Symbol)
        msg = t(msg, args)
      end
      # TODO: logging
      # TODO: Return ErrorsList, let caller transform to_s
      # TODO: send (selected) errors to admin
      $stderr.puts "#{msg}\n#{t(:greetings)}\n"
      exit 1
    end

    def t(sym, args={})
      # TODO: Implement rails-less
      I18n.t(sym, {scope: [:schleuder]}.merge(args))
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
        error(:no_such_list)
      end
      # This cannot be put in List, as Mail wouldn't know it then.
      ENV['GNUPGHOME'] = @list.listdir
    end

  end
end
