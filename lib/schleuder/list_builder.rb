module Schleuder
  class ListBuilder
    def initialize(listname, adminemail=nil, adminkeypath=nil)
      # TODO: test list-name
      @listname = listname
      @adminemail = adminemail
      @adminkeypath = adminkeypath
      @errors = ErrorsList.new
    end

    def errors?
      ! @errors.empty?
    end

    def errors
      @errors
    end

    def run
      if List.where(email: @listname).present?
        @errors << Errors::ListExists.new(@listname)
        return [@errors, nil]
      end

      @list_dir = List.listdir(@listname)
      if ! File.exists?(@list_dir)
        FileUtils.mkdir_p(@list_dir, :mode => 0700)
      else
        test_list_dir
        return errors if errors?
      end

      # TODO: get defaults from some file, not from database
      list = List.new(email: @listname)

      list_key = gpg.keys("<#{@listname}>").first
      if list_key.nil?
        list_key = create_key(list)
      end

      return errors if errors?

      list.fingerprint = list_key.fingerprint
      list.save!

      if @adminkeypath.present?
        if ! File.readable?(@adminkeypath)
          errors << FileNotFound.new(@adminkeypath)
        end
        imports = list.import_key(File.read(@adminkeypath)).imports
        # Get the fingerprint of the imported key if it was exactly one.
        if imports.size == 1
          admin_fpr = imports.first.fingerprint
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
        sub = list.subscribe(@adminemail, admin_fpr)
        if sub.errors.present?
          errors << ActiveModelError.new(sub.errors)
        end
      end

      [errors, list]
    end

    def gpg
      @gpg_ctx ||= begin
        ENV["GNUPGHOME"] = @list_dir
        GPGME::Ctx.new
      end
    end

    def create_key(list)
      # TODO: fix using a passphrase.
      #phrase_container = Passphrase.new
      #phrase = phrase_container.generate(32) # TODO get size from config

      puts "Generating key-pair, this could take a while..."
      begin
        gpg.generate_key(key_params(list))
      rescue => exc
        @errors << exc
        return
      end

      # Get key without knowing the fingerprint yet.
      keys = gpg.keys("<#{@listname}>")
      if keys.empty?
        @errors << Errors::KeyGenerationFailed.new(@list_dir, @listname)
      elsif keys.size > 1
        @errors << Errors::TooManyKeys.new(@list_dir, @listname)
      else
        # Add UIDs for -owner and -request.
        err, string = keys.first.adduid(list.email, list.request_address, @list_dir)
        if err > 0
          @errors << Errors::KeyAdduidFailed.new(string)
        end

        err, string = keys.first.adduid(list.email, list.owner_address, @list_dir)
        if err > 0
          @errors << Errors::KeyAdduidFailed.new(string)
        end
      end

      puts "Done."
      keys.first
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
        @errors << Errors::ListdirProblem.new(@list_dir, :not_a_directory)
      end

      if Dir.entries(@list_dir).size > 2
        @errors << Errors::ListdirProblem.new(@list_dir, :not_empty)
      end

      if ! File.writable?(@list_dir)
        @errors << Errors::ListdirProblem.new(@list_dir, :not_writable)
      end
    end

  end
end
