module Schleuder
  class Runner
    def run(msg, recipient)
      # TODO: to check this here is quite late. We already loaded all the libs, connected to the database, etc. Maybe check earlier?
      error = check_throttle
      return error if error

      error = setup_list(recipient)
      return error if error

      logger.info "Parsing incoming email."
      @mail = Mail.create_message_to_list(msg, recipient, list)

      error = run_filters(Filters::Runner::PRE_SETUP_FILTERS)
      return error if error

      begin
        # This decrypts, verifies, etc.
        @mail = @mail.setup
      rescue GPGME::Error::DecryptFailed
        logger.warn "Decryption of incoming message failed."
        return Errors::DecryptionFailed.new(list)
      end

      error = run_filters(Filters::Runner::POST_SETUP_FILTERS)
      return error if error

      if ! @mail.was_validly_signed?
        logger.debug "Message was not validly signed, adding subject_prefix_in"
        @mail.add_subject_prefix_in!
      end

      if ! @mail.was_encrypted?
        logger.debug "Message was not encrypted, skipping plugins"
      elsif @mail.was_validly_signed?
        # Plugins
        logger.debug "Message was encrypted and validly signed"
        PluginRunners::ListPluginsRunner.run(list, @mail).compact
      end

      # Don't send empty messages over the list.
      if @mail.empty?
        logger.info "Message found empty, not sending it to list."
        return Errors::MessageEmpty.new(@list)
      end

      logger.debug "Adding subject_prefix"
      @mail.add_subject_prefix!

      # Subscriptions
      logger.debug "Creating clean copy of message"
      copy = @mail.clean_copy(true)
      list.send_to_subscriptions(copy)

      Throttle.unregister
      nil
    end

    private

    def list
      @list
    end

    def run_filters(filters)
      error = filters_runner.run(@mail, filters)
      if error
        if list.bounces_notify_admins?
          text = "#{I18n.t('.bounces_notify_admins')}\n\n#{error}"
          # TODO: raw_source is mostly blank?
          logger.notify_admin text, @mail.original_message, I18n.t('notice')
        end
        return error
      end
    end

    def filters_runner
      @filters_runner ||= Filters::Runner.new(list)
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

      # Check basic sanity of list.
      %w[fingerprint key secret_key admins].each do |attrib|
        if @list.send(attrib).blank?
          return log_and_return(Errors::ListPropertyMissing.new(attrib))
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

    def check_throttle
      error = ensure_run_state_dir
      return error if error.present?

      if ! Throttle.register
        # Tell the MTA to try again later
        exit 127
      end
      nil
    end

    def ensure_run_state_dir
      if ! File.exist?(ENV['SCHLEUDER_RUN_STATE_DIR'])
        return RuntimeError.new("Required directory #{ENV['SCHLEUDER_RUN_STATE_DIR']} does not exist, run `schleuder install` to fix this.")
      else
        if ! File.writable?(ENV['SCHLEUDER_RUN_STATE_DIR'])
          return RuntimeError.new("#{ENV['SCHLEUDER_RUN_STATE_DIR']} is not writable, please fix this.")
        end
      end
      nil
    end
  end
end
