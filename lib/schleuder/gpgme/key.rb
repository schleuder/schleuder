module GPGME
  class Key
    # Overwrite to specify the full fingerprint instead of the short key-ID.
    def to_s
      primary_subkey = subkeys[0]
      s = sprintf("%s   %4d%s/%s %s\n",
                  primary_subkey.secret? ? 'sec' : 'pub',
                  primary_subkey.length,
                  primary_subkey.pubkey_algo_letter,
                  primary_subkey.fingerprint,
                  primary_subkey.timestamp.strftime('%Y-%m-%d'))
      uids.each do |user_id|
        s << "uid\t\t#{user_id.name} <#{user_id.email}>\n"
      end
      subkeys.each do |subkey|
        s << subkey.to_s
      end
      s
    end

    def armored
      "#{self.to_s}\n\n#{export(armor: true).read}"
    end

    # Force encoding, some databases save "ASCII-8BIT" as binary data.
    alias_method :orig_fingerprint, :fingerprint
    def fingerprint
      orig_fingerprint.encode(Encoding::US_ASCII)
    end

    def usable?
      usability_issue.blank?
    end

    def usability_issue
      if trust.present?
        trust
      elsif ! usable_for?(:encrypt)
        "not capable of encryption"
      else
        nil
      end
    end

    def set_primary_uid(email)
      # We rely on the order of UIDs here. Seems to work.
      index = self.uids.map(&:email).index(email)
      uid_number = index + 1
      primary_set = false
      args = "--edit-key '#{self.fingerprint}' #{uid_number}"
      errors, _ = GPGME::Ctx.gpgcli_expect(args) do |line|
        case line.chomp
        when /keyedit.prompt/
          if ! primary_set
            primary_set = true
            "primary"
          else
            "save"
          end
        when /USERID_HINT|NEED_PASSPHRASE|GOOD_PASSPHRASE|GOT_IT|KEY_CONSIDERED/
          nil
        else
          return "Unexpected line: #{line}"
        end
      end
      errors.join
    end

    def adduid(uid, email)
      # This block can be deleted once we cease to support gnupg 2.0.
      if ! GPGME::Ctx.sufficient_gpg_version?('2.1.4')
        return adduid_expect(uid, email)
      end

      # Specifying the key via fingerprint apparently doesn't work.
      errors, _ = GPGME::Ctx.gpgcli("--quick-adduid #{uid} '#{uid} <#{email}>'")
      errors.join
    end

    # This method can be deleted once we cease to support gnupg 2.0.
    def adduid_expect(uid, email)
      args = "--allow-freeform-uid --edit-key '#{self.fingerprint}' adduid"
      errors, _ = GPGME::Ctx.gpgcli_expect(args) do |line|
        case line.chomp
        when /keygen.name/
          uid
        when /keygen.email/
          email
        when /keygen.comment/
          ''
        when /keyedit.prompt/
          "save"
        else
          nil
        end
      end
      errors.join
    end

    def clearpassphrase(oldpw)
      # This block can be deleted once we cease to support gnupg 2.0.
      if ! GPGME::Ctx.sufficient_gpg_version?('2.1.0')
        return clearpassphrase_v20(oldpw)
      end

      oldpw_given = false
      # Don't use '--passwd', it claims to fail (even though it factually doesn't).
      args = "--pinentry-mode loopback --edit-key '#{self.fingerprint}' passwd"
      errors, _, exitcode = GPGME::Ctx.gpgcli_expect(args) do |line|
        case line
        when /passphrase.enter/
          if ! oldpw_given
            oldpw_given = true
            oldpw
          else
            ""
          end
        when /BAD_PASSPHRASE/
          [false, 'bad passphrase']
        when /change_passwd.empty.okay/
          'y'
        when /keyedit.prompt/
          "save"
        else
          nil
        end
      end

      # Only show errors if something apparently went wrong. Otherwise we might
      # leak useless strings from gpg and make the caller report errors even
      # though this method succeeded.
      if exitcode > 0
        errors.join
      else
        nil
      end
    end

    # This method can be deleted once we cease to support gnupg 2.0.
    def clearpassphrase_v20(oldpw)
      start_gpg_agent(oldpw)
      # Don't use '--passwd', it claims to fail (even though it factually doesn't).
      errors, _, exitcode = GPGME::Ctx.gpgcli_expect("--edit-key '#{self.fingerprint}' passwd") do |line|
        case line
        when /BAD_PASSPHRASE/
          [false, 'bad passphrase']
        when /change_passwd.empty.okay/
          'y'
        when /keyedit.prompt/
          "save"
        else
          nil
        end
      end
      stop_gpg_agent

      # Only show errors if something apparently went wrong. Otherwise we might
      # leak useless strings from gpg and make the caller report errors even
      # though this method succeeded.
      if exitcode > 0
        errors.join
      else
        nil
      end
    end

    # This method can be deleted once we cease to support gnupg 2.0.
    def stop_gpg_agent
      # gpg-agent terminates itself if its socket goes away.
      GPGME::Ctx.delete_daemon_socket('gpg-agent')
    end

    def start_gpg_agent(oldpw)
      ENV['PINENTRY_USER_DATA'] = oldpw
      pinentry = File.join(ENV['SCHLEUDER_ROOT'], 'bin', 'pinentry-clearpassphrase')
      GPGME::Ctx.spawn_daemon('gpg-agent', "--use-standard-socket --pinentry-program #{pinentry}")
    end
  end
end
