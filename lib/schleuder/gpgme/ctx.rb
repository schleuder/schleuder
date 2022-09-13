module GPGME
  class Ctx
    IMPORT_FLAGS = {
      'new_key' => 1,
      'new_uids' => 2,
      'new_signatures' => 4,
      'new_subkeys' => 8
    }

    def find_keys(input=nil, secret_only=nil)
      keys(normalize_key_identifier(input), secret_only)
    end

    def find_distinct_key(input=nil, secret_only=nil)
      keys = keys(normalize_key_identifier(input), secret_only)
      if keys.size == 1
        keys.first
      else
        nil
      end
    end

    def normalize_key_identifier(input)
      case input
      when /.*?([^ <>]+@[^ <>]+).*?/
        "<#{$1}>"
      when /^http/
        input
      when Conf::FINGERPRINT_REGEXP
        "0x#{input.gsub(/^0x/, '')}"
      else
        input
      end
    end

    # Tell gpgme to use the given binary.
    def self.set_gpg_path_from_env
      path = ENV['GPGBIN'].to_s
      if ! path.empty?
        Schleuder.logger.debug "setting gpg to use #{path}"
        GPGME::Engine.set_info(GPGME::PROTOCOL_OpenPGP, path, ENV['GNUPGHOME'])
        if gpg_engine.version.nil?
          $stderr.puts "Error: The binary you specified doesn't provide a gpg-version."
          exit 1
        end
      end
    end

    def self.sufficient_gpg_version?(required)
      Gem::Version.new(required) <= Gem::Version.new(gpg_engine.version)
    end

    def self.check_gpg_version
      if ! sufficient_gpg_version?('2.2')
        $stderr.puts "Error: GnuPG version >= 2.2 required.\nPlease install it and/or provide the path to the binary via the environment-variable GPGBIN.\nExample: GPGBIN=/opt/gpg2/bin/gpg ..."
        exit 1
      end
    end

    def self.gpg_engine
      GPGME::Engine.info.find {|e| e.protocol == GPGME::PROTOCOL_OpenPGP }
    end

    def import_keys(input)
      # Import through gpgcli so we can use import-filter. GPGME still does
      # not provide that feature (as of summer 2021): <https://dev.gnupg.org/T4721> :(
      gpgerr, gpgout, exitcode = self.class.gpgcli("#{import_filter_arg} --import") do |stdin, stdout, stderr|
        # Wrap this into a block because gpg breaks the pipe if it encounters invalid data.
        begin
          stdin.print input
        rescue Errno::EPIPE
        end
        stdin.close
        stdout.readlines
      end
      if exitcode > 0
        RuntimeError.new(gpgerr.join("\n"))
      else
        gpgout
      end
    end

    # TODO: What does this return if no key could be imported?
    def translate_import_output(locale_key, gpgoutput)
      import_states = translate_import_data(gpgoutput)
      strings = import_states.map do |fingerprint, states|
        key = find_distinct_key(fingerprint)
        I18n.t(locale_key, key_summary: key.summary,
                           states: states.to_sentence)
      end
      strings
    end

    def translate_import_data(gpgoutput)
      if gpgoutput.is_a?(StandardError)
        return gpgoutput
      end
      result = {}
      gpgoutput.grep(/IMPORT_OK/) do |import_ok|
        next if import_ok.blank?

        import_status, fingerprint = import_ok.split(/\s/).slice(2, 2)
        import_status = import_status.to_i
        states = []

        if import_status == 0
          states << I18n.t('import_states.unchanged')
        else
          IMPORT_FLAGS.each do |text, int|
            if (import_status & int) > 0
              states << I18n.t("import_states.#{text}")
            end
          end
        end
        result[fingerprint] = states
      end
      result
    end

    # Unfortunately we can't distinguish between a failure to connect the
    # keyserver, and a failure to find the key on the server. So we try to
    # filter misleading errors to check if there are any to be reported.
    def refresh_key_filter_messages(strings)
      strings.reject do |line|
        line.chomp == 'gpg: keyserver refresh failed: No data' ||
          line.match(/^gpgkeys: key .* not found on keyserver/) ||
          line.match(/^gpg: refreshing /) ||
          line.match(/^gpg: requesting key /) ||
          line.match(/^gpg: no valid OpenPGP data found/)
      end
    end

    def self.gpgcli(args)
      exitcode = -1
      errors = []
      output = []
      base_cmd = gpg_engine.file_name
      base_args = '--no-greeting --no-permission-warning --quiet --armor --trust-model always --no-tty --command-fd 0 --status-fd 1'
      cmd = [base_cmd, base_args, args].flatten.join(' ')
      Open3.popen3(cmd) do |stdin, stdout, stderr, thread|
        if block_given?
          output = yield(stdin, stdout, stderr)
        else
          output = stdout.readlines
        end
        stdin.close if ! stdin.closed?
        errors = stderr.readlines
        exitcode = thread.value.exitstatus
      end

      [errors, output, exitcode]
    rescue Errno::ENOENT
      raise 'Need gpg in $PATH or in $GPGBIN'
    end

    def import_filter_arg
      %{ --import-filter drop-sig='sig_created_d > 0000-00-00'}
    end
  end
end
