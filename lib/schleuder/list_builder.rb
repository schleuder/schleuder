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
      hash = Conf.load_config('list-defaults', ENV['SCHLEUDER_LIST_DEFAULTS'])
      if ! hash.kind_of?(Hash)
        raise Errors::LoadingListSettingsFailed.new
      end
      hash
    rescue Psych::SyntaxError
      raise Errors::LoadingListSettingsFailed.new
    end

    def run
      if @listname !~ /\A.+@.+\z/
        raise Errors::InvalidListname.new(@listname)
      end

      if List.where(email: @listname).present?
        raise Errors::ListExists.new(@listname)
      end

      @list_dir = List.listdir(@listname)
      if File.exists?(@list_dir)
        test_list_dir
      else
        FileUtils.mkdir_p(@list_dir, :mode => 0700)
      end

      settings = read_default_settings

      settings.merge!(@list_attributes)

      begin
        list = List.new(settings)
      rescue ActiveRecord::UnknownAttributeError => exc
        raise Errors::UnknownListOption.new(exc)
      end

      if @fingerprint
        list.fingerprint = @fingerprint
      else
        list_key = gpg.keys("<#{@listname}>").first
        if list_key.nil?
          list_key = create_key(list)
        end
        list.fingerprint = list_key.fingerprint
      end

      list.save!

      if @adminkey.present?
        result = list.import_key(@adminkey)
        # Get the fingerprint of the imported key if it was exactly one.
        if result.keys.size == 1
          admin_fpr = result.keys.first
        end
      end

      if @adminemail.present?
        # Try if we can find the admin-key "manually". Maybe it's present
        # in the keyring aleady.
        if ! admin_fpr
          keys = gpg.keys("<#{@adminemail}>")
          if keys.size == 1
            admin_fpr = keys.first.fingerprint
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
      puts "Generating key-pair, this could take a while..."
      gpg.generate_key(key_params(list))

      # Get key without knowing the fingerprint yet.
      keys = gpg.keys("<#{@listname}>")
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
        $stderr.puts Errors::KeyAdduidFailed.new(string)
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

    def test_list_dir
      # Check if listdir is usable.
      if ! File.directory?(@list_dir)
        raise Errors::ListdirProblem.new(@list_dir, :not_a_directory)
      end

      if ! File.writable?(@list_dir)
        raise Errors::ListdirProblem.new(@list_dir, :not_writable)
      end
    end

  end
end
