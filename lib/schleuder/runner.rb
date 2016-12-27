module Schleuder
  class Runner
    def run(msg, recipient)
      error = setup_list(recipient)
      return error if error

      logger.info "Parsing incoming email."
      begin
        # This decrypts, verifies, etc.
        @mail = Mail.new(msg)
        @mail = @mail.setup(recipient, list)
      rescue GPGME::Error::DecryptFailed
        logger.warn "Decryption of incoming message failed."
        return Errors::DecryptionFailed.new(list)
      end

      # Filters
      error = Filters::Runner.run(list, @mail)
      if error
        if list.bounces_notify_admins?
          text = "#{I18n.t('.bounces_notify_admins')}\n\n#{error}"
          # TODO: raw_source is mostly blank?
          logger.notify_admin text, @mail.original_message, I18n.t('notice')
        end
        return error
      end

      if ! @mail.was_validly_signed?
        logger.debug "Message was not validly signed, adding subject_prefix_in"
        @mail.add_subject_prefix_in!
      end

      if ! @mail.was_encrypted?
        logger.debug "Message was not encrypted, skipping plugins"
      elsif @mail.was_validly_signed?
        # Plugins
        logger.debug "Message was encrypted and validly signed"
        output = Plugins::Runner.run(list, @mail).compact

        # Any output will be treated as error-message. Text meant for users
        # should have been put into the mail by the plugin.
        output.each do |something|
          @mail.add_pseudoheader(:error, something.to_s) if something.present?
        end
      end

      # Don't send empty messages over the list.
      if @mail.empty?
        logger.info "Message found empty, not sending it to list."
        return Errors::MessageEmpty.new(@list)
      end

      logger.debug "Adding subject_prefix"
      @mail.add_subject_prefix!

      # Subscriptions
      send_to_subscriptions
      nil
    end

    private

    def send_to_subscriptions
      logger.debug "Sending to subscriptions."
      logger.debug "Creating clean copy of message"
      new = @mail.clean_copy(true)
      list.subscriptions.each do |subscription|
        begin
          subscription.send_mail(new)
        rescue => exc
          logger.error exc
        end
      end
    end

    def list
      @list
    end

    def logger
      list.present? && list.logger || Schleuder.logger
    end

    def log_and_return(error)
      Schleuder.logger.error(error)
      error
    end

    def setup_list(recipient)
      return @list if @list

      logger.info "Loading list '#{recipient}'"
      if ! @list = List.by_recipient(recipient)
        return log_and_return(Errors::ListNotFound.new(recipient))
      end

      # Check basic sanity of list.
      %w[fingerprint key secret_key admins].each do |attrib|
        if @list.send(attrib).blank?
          return log_and_return(Errors::ListPropertyMissing.new(attrib))
        end
      end

      # Check neccessary permissions of crucial files.
      if ! File.exist?(@list.listdir)
        return log_and_return(Errors::ListdirProblem.new(@list.listdir, :not_existing))
      elsif ! File.directory?(@list.listdir)
        return log_and_return(Errors::ListdirProblem.new(@list.listdir, :not_a_directory))
      elsif ! File.readable?(@list.listdir)
        return log_and_return(Errors::ListdirProblem.new(@list.listdir, :not_readable))
      elsif ! File.writable?(@list.listdir)
        return log_and_return(Errors::ListdirProblem.new(@list.listdir, :not_writable))
      else
        if File.exist?(@list.logfile) && ! File.writable?(@list.logfile)
          return log_and_return(Errors::ListdirProblem.new(@list.logfile, :not_writable))
        end
      end


      # Set locale
      if I18n.available_locales.include?(@list.language.to_sym)
        I18n.locale = @list.language.to_sym
      end

      # This cannot be put in List, as Mail wouldn't know it then.
      logger.debug "Setting GNUPGHOME to #{@list.listdir}"
      ENV['GNUPGHOME'] = @list.listdir
      nil
    end
  end
end
