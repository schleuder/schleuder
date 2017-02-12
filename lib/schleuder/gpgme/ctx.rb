module GPGME
  class Ctx
    FINGERPRINT_REGEXP = /\A(0x)?[a-f0-9]{32,}\z/i
    IMPORT_FLAGS = {
      'new_key' => 1,
      'new_uids' => 2,
      'new_signatures' => 4,
      'new_subkeys' => 8
    }

    def keyimport(keydata)
      self.import_keys(GPGME::Data.new(keydata))
      result = self.import_result
      result.imports.map(&:set_action)
      result
    end

    def find_keys(input=nil, secret_only=nil)
      _, input = clean_and_classify_input(input)
      keys(input, secret_only)
    end

    def clean_and_classify_input(input)
      case input
      when /.*?([^ <>]+@[^ <>]+).*?/
        [:email, "<#{$1}>"]
      when /^http/
        [:url, input]
      when /\A(0x)?([a-f0-9]{32,})\z/i
        [:fingerprint, "0x#{$2}"]
      else
        [nil, input]
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
      if ! sufficient_gpg_version?('2.0')
        $stderr.puts "Error: GnuPG version >= 2.0 required.\nPlease install it and/or provide the path to the binary via the environment-variable GPGBIN.\nExample: GPGBIN=/opt/gpg2/bin/gpg ..."
        exit 1
      end
    end

    def self.gpg_engine
      GPGME::Engine.info.find {|e| e.protocol == GPGME::PROTOCOL_OpenPGP }
    end

    def self.refresh_keys(keys)
      output = []
      base_args = "--no-auto-check-trustdb --keyserver #{Conf.keyserver} --refresh-keys"
      keys.each do |key|
        args = "#{base_args} #{key.fingerprint}"
        err, gpgout, _ = gpgcli(args)
        gpgout = filter_gpgcli_output(gpgout)
        output << filter_gpgcli_output(err)
        # Add any gpgkeys-message (gpg 2.0 writes those messages to stdout).
        # Those could e.g. report a failure to connect to the keyserver.
        output << gpgout.select { |line| line.match(/^gpgkeys: .*$/) }

        translate_import_data(gpgout).each do |fingerprint, states|
          output << I18n.t("key_updated", { fingerprint: fingerprint,
                                            states: states.join(', ') })
          output << "\n"
        end
        sleep rand(1.0..5.0)
      end
      gpgcli("--check-trustdb")
      output.flatten.uniq.join
    end

    def fetch_key(input)
      arguments, error = fetch_key_gpg_arguments_for(input)
      return error if error

      gpgerr, gpgout, exitcode = self.class.gpgcli(arguments)

      # Unfortunately gpg doesn't exit with code > 0 if `--fetch-key` fails.
      if exitcode > 0 || gpgerr.grep(/ unable to fetch /).presence
        "Fetching #{input} did not succeed:\n#{gpgerr.join("\n")}"
      else
        translate_output('key_fetched', gpgout)
      end
    end

    def fetch_key_gpg_arguments_for(input)
      case input
      when FINGERPRINT_REGEXP
        "--keyserver #{Conf.keyserver} --recv-key #{input}"
      when /^http/
        "--fetch-key #{input}"
      when /@/
        # --recv-key doesn't work with email-addresses, so we use --locate-key
        # restricted to keyservers.
        "--keyserver #{Conf.keyserver} --auto-key-locate keyserver --locate-key #{input}"
      else
        [nil, I18n.t("fetch_key.invalid_input")]
      end
    end

    def translate_output(locale_key, gpgoutput)
      import_states = translate_import_data(gpgoutput)
      strings = import_states.map do |fingerprint, states|
        I18n.t(locale_key, { fingerprint: fingerprint,
                             states: states.join(', ') })
      end
      strings.join("\n")
    end

    def translate_import_data(gpgoutput)
      self.class.translate_import_data(gpgoutput)
    end

    def self.translate_import_data(gpgoutput)
      result = {}
      gpgoutput.grep(/IMPORT_OK/) do |import_ok|
        next if import_ok.blank?

        import_status, fingerprint = import_ok.split(/\s/).slice(2, 2)
        import_status = import_status.to_i
        next if import_status == 0

        states = []
        IMPORT_FLAGS.each do |text, int|
          if (import_status & int) > 0
            states << I18n.t("import_states.#{text}")
          end
        end
        result[fingerprint] = states
      end
      result
    end

    # Unfortunately we can't distinguish between a failure to connect the
    # keyserver, and a failure to find the key on the server. So we try to
    # filter misleading errors to check if there are any to be reported.
    def self.filter_gpgcli_output(strings)
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
      base_args = "--no-greeting --no-permission-warning --quiet --armor --trust-model always --no-tty --command-fd 0 --status-fd 1"
      cmd = [base_cmd, base_args, args].flatten.join(' ')
      Open3.popen3(cmd) do |stdin, stdout, stderr, thread|
        if block_given?
          output = yield(stdin, stdout, stderr)
        else
          output = stdout.readlines
        end
        stdin.close
        errors = stderr.readlines
        exitcode = thread.value.exitstatus
      end

      [errors, output, exitcode]
    rescue Errno::ENOENT
      raise 'Need gpg in $PATH or in $GPGBIN'
    end

    def self.gpgcli_expect(args)
      gpgcli(args) do |stdin, stdout, stderr|
        counter = 0
        while line = stdout.gets rescue nil
          counter += 1
          if counter > 1042
            return "Too many input-lines from gpg, something went wrong"
          end
          output, error = yield(line.chomp)
          if output == false
            return error
          elsif output
            stdin.puts output
          end
        end
      end
    end

    def self.spawn_daemon(name, args)
      delete_daemon_socket(name)
      cmd = "#{name} #{args} --daemon > /dev/null 2>&1"
      if ! system(cmd)
        return [false, "#{name} exited with code #{$?}"]
      end
    end

    def self.delete_daemon_socket(name)
      path = File.join(ENV["GNUPGHOME"], "S.#{name}")
      if File.exist?(path)
        File.delete(path)
      end
    end
  end
end
