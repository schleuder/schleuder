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
        puts "setting gpg to use #{path}"
        GPGME::Engine.set_info(GPGME::PROTOCOL_OpenPGP, path, ENV['GNUPGHOME'])
        if gpg_engine.version.nil?
          $stderr.puts "Error: The binary you specified doesn't provide a gpg-version."
          exit 1
        end
      end
    end

    def self.sufficient_gpg_version?(required)
      Gem::Version.new(required) < Gem::Version.new(gpg_engine.version)
    end

    def self.check_gpg_version
      set_gpg_path_from_env
      if ! sufficient_gpg_version?('2.0')
        $stderr.puts "Error: GnuPG version >= 2.0 required.\nPlease install it and/or provide the path to the binary via the environment-variable GPGBIN.\nExample: GPGBIN=/opt/gpg2/bin/gpg ..."
        exit 1
      end
    end

    def self.gpg_engine
      GPGME::Engine.info.find {|e| e.protocol == GPGME::PROTOCOL_OpenPGP }
    end

    def refresh_keys
      exitcode, output = exec_gpg_cli("--refresh-keys --batch")
      output
    end

    def check_keys
      now = Time.now
      checkdate = now + (60 * 60 * 24 * 14) # two weeks
      unusable = []
      expiring = []

      keys('').each do |key|
        expiry = key.subkeys.first.expires
        if expiry && expiry > now && expiry < checkdate
          # key expires in the near future
          expdays = ((exp - now)/86400).to_i
          expiring << [key, expdays]
        end

        if key.trust
          unusable << [key, key.trust]
        end
      end

      text = ''
      expiring.each do |key,days|
        text << I18n.t('key_expires', {
                          days: days,
                          fingerprint: key.fingerprint,
                          email: key.email
                      })
      end

      unusable.each do |key,trust|
        text << I18n.t('key_unusable', {
                          trust: Array(trust).join(', '),
                          fingerprint: key.fingerprint,
                          email: key.email
                      })
      end
      text
    end
  

    private


    # TODO: refactor with Key#adduid
    def exec_gpg_cli(args)
      output = ''
      exitcode = -1
      cmd = "gpg #{args}"
      Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
        output = stdout_err.readlines.join
        exitcode = wait_thr.value
      end
      [exitcode, output]
    end

  end
end
