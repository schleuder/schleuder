module Schleuder
  class ListBuilder
    def initialize(list_attributes, adminemail=nil, adminkey=nil)
      @list_attributes = list_attributes.with_indifferent_access
      @listname = list_attributes[:email]
      @fingerprint = list_attributes[:fingerprint]
      @adminemail = adminemail
      @adminkey = adminkey
      @messages = []
    end

    def read_default_settings
      hash = Conf.load_config('list-defaults', ENV['SCHLEUDER_LIST_DEFAULTS'])
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
        return [nil, "Given 'listname' is not a valid email address."]
      end

      settings = read_default_settings.merge(@list_attributes)
      list = List.new(settings)

      @list_dir = list.listdir
      create_or_test_list_dir

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
          admin_key = list.keys_by_email(@adminemail).first
          if admin_key.present?
            admin_fpr = admin_key.fingerprint
          end
        end
        sub = list.subscribe(@adminemail, admin_fpr, true)
        if sub.errors.present?
          raise ActiveModelError.new(sub.errors)
        end
      end

      [list, @messages]
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
      keys = list.keys_by_email(@listname)
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
      gpg_version = `gpg --version`.lines.first.split.last
      # Gem::Version knows that e.g. ".10" is higher than ".4", String doesn't.
      if Gem::Version.new(gpg_version) < Gem::Version.new("2.1.4")
        string = "Couldn't add additional UIDs to the list's key automatically\n(GnuPG version >= 2.1.4 is required, using 'gpg' in PATH).\nPlease add these UIDs to the list's key manually: #{list.request_address}, #{list.owner_address}."
        # Don't add to errors because then the list isn't saved.
        @messages << Errors::KeyAdduidFailed.new(string).message
        return false
      end

      [list.request_address, list.owner_address].each do |address|
        err, string = key.adduid(list.email, address, list.listdir)
        if err > 0
          raise Errors::KeyAdduidFailed.new(string)
        end
      end
    rescue Errno::ENOENT
      raise Errors::KeyAdduidFailed.new('Need gpg in $PATH')
    end

    def key_params(list)
      "
        <GnupgKeyParms format=\"internal\">
        Key-Type: RSA
        Key-Length: 4096
        Subkey-Type: RSA
        Subkey-Length: 4096
        Name-Real: #{list.email}
        Name-Email: #{list.email}
        Expire-Date: 0
        %no-protection
        </GnupgKeyParms>

      "
    end

    def create_or_test_list_dir
      if File.exists?(@list_dir)
        if ! File.directory?(@list_dir)
          raise Errors::ListdirProblem.new(@list_dir, :not_a_directory)
        end

        if ! File.writable?(@list_dir)
          raise Errors::ListdirProblem.new(@list_dir, :not_writable)
        end
      else
        FileUtils.mkdir_p(@list_dir, mode: 0700)
      end
    end

  end
end
