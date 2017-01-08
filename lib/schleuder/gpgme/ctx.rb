module GPGME
  class Ctx
    def keyimport(*args)
      self.import_keys(*args)
      result = self.import_result
      result.imports.map(&:set_action)
      result
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

    def self.gpgcli(args)
      exitcode = -1
      errors = ''
      output = ''
      base_cmd = gpg_engine.file_name
      base_args = "--armor --trust-model always --quiet --no-tty --command-fd 0 --status-fd 1"
      cmd = [base_cmd, base_args, args].flatten.join(' ')
      Open3.popen3(cmd) do |stdin, stdout, stderr, thread|
        if block_given?
          output = yield(stdin, stdout, stderr)
        end
        stdin.close
        errors = stderr.readlines
        exitcode = thread.value.exitstatus
      end

      if output.present?
        output
      elsif exitcode > 0
        errors.join("\n")
      else
        nil
      end
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
      nil
    end
  end
end
