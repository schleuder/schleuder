module Schleuder
  class ListBuilder
    def initialize(list_attributes, adminemail=nil, adminkey=nil)
      @list_attributes = list_attributes.with_indifferent_access
      @listname = list_attributes[:email]
      @fingerprint = list_attributes[:fingerprint]
      @adminemail = adminemail
      @adminkey = adminkey
    end

    def read_default_settings
      hash = YAML.load_file(ENV['SCHLEUDER_LIST_DEFAULTS'])
      if ! hash.kind_of?(Hash)
        raise Errors::LoadingListSettingsFailed.new
      end
      hash
    rescue Psych::SyntaxError
      raise Errors::LoadingListSettingsFailed.new
    end

    def run
      Schleuder.logger.info "Building new list"

      if @listname.blank? || ! @listname.match(Conf::EMAIL_REGEXP)
        return [nil, {'email' => ["'#{@listname}' is not a valid email address"]}]
      end

      settings = read_default_settings.merge(@list_attributes)
      list = List.new(settings)

      @list_dir = list.listdir
      create_or_test_dir(@list_dir)
      # In case listlogs_dir != lists_dir we have to create the basedir of the
      # list's log-file.
      create_or_test_dir(File.dirname(list.logfile))

      if list.fingerprint.blank?
        list_key = gpg.keys("<#{list.email}>").first
        if list_key.nil?
          list_key = create_key(list)
        end
        list.fingerprint = list_key.fingerprint
      end

      if ! list.valid?
        return list
      end

      list.save!

      if @adminkey.present?
        import_result = list.import_key(@adminkey)
        # Get the fingerprint of the imported key if it was exactly one. If it
        # was imported or was already present doesn't matter.
        if import_result.considered == 1
          admin_fpr = import_result.imports.first.fpr
        end
      end

      if @adminemail.present?
        # Try if we can find the admin-key "manually". Maybe it's present
        # in the keyring aleady.
        if admin_fpr.blank?
          key = list.distinct_key(@adminemail)
          if key
            admin_fpr = key.fingerprint
          end
        end
        sub = list.subscribe(@adminemail, admin_fpr, true)
        if sub.errors.present?
          raise ActiveModelError.new(sub.errors)
        end
      end

      list
    end

    def gpg
      @gpg_ctx ||= begin
        ENV["GNUPGHOME"] = @list_dir
        GPGME::Ctx.new
      end
    end

    def create_key(list)
      Schleuder.logger.info "Generating key-pair, this could take a while..."
      gpg.generate_key(key_params(list))

      # Get key without knowing the fingerprint yet.
      keys = list.keys(@listname)
      if keys.empty?
        raise Errors::KeyGenerationFailed.new(@list_dir, @listname)
      elsif keys.size > 1
        raise Errors::TooManyKeys.new(@list_dir, @listname)
      else
        adduids(list, keys.first)
      end

      keys.first
    end

    def adduids(list, key)
      # Add UIDs for -owner and -request.
      [list.request_address, list.owner_address].each do |address|
        err = key.adduid(list.email, address)
        if err.present?
          raise err
        end
      end
      # Go through list.key() to re-fetch the key from the keyring, otherwise
      # we don't see the new UIDs.
      errors = list.key.set_primary_uid(list.email)
      if errors.present?
        raise errors
      end
    rescue => exc
      raise Errors::KeyAdduidFailed.new(exc.to_s)
    end

    def key_params(list)
      "
        <GnupgKeyParms format=\"internal\">
        Key-Type: RSA
        Key-Length: 4096
        Key-Usage: sign
        Subkey-Type: RSA
        Subkey-Length: 4096
        Subkey-Usage: encrypt
        Name-Real: #{list.email}
        Name-Email: #{list.email}
        Expire-Date: 0
        %no-protection
        </GnupgKeyParms>

      "
    end

    def create_or_test_dir(dir)
      if File.exists?(dir)
        if ! File.directory?(dir)
          raise Errors::ListdirProblem.new(dir, :not_a_directory)
        end

        if ! File.writable?(dir)
          raise Errors::ListdirProblem.new(dir, :not_writable)
        end
      else
        FileUtils.mkdir_p(dir)
      end
    end

  end
end
