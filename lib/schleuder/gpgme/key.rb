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
        when /USERID_HINT|GOT_IT|GOOD_PASSPHRASE/
          nil
        else
          [false, "Unexpected line: #{line}"]
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
        when /USERID_HINT|NEED_PASSPHRASE|GOT_IT|GOOD_PASSPHRASE|MISSING_PASSPHRASE|KEY_CONSIDERED|INQUIRE_MAXLEN|PROGRESS/
          nil
        else
          [false, "Unexpected line: #{line}"]
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
      ENV['PINENTRY_USER_DATA'] = oldpw
      pinentry = File.join(ENV['SCHLEUDER_ROOT'], 'bin', 'pinentry-clearpassphrase')
      delete_gpg_agent_socket
      gpg_agent_log = "/tmp/schleuder-gpg-agent-#{rand}.log"
      gpg_agent_cmd = "gpg-agent --use-standard-socket --pinentry-program #{pinentry} --daemon > #{gpg_agent_log} 2>&1"
      if ! system(gpg_agent_cmd)
        return [false, "gpg-agent exited with code #{$?}, output in #{gpg_agent_log}"]
      end
      # Don't use '--passwd', it claims to fail (even though it factually doesn't).
      errors, _, exitcode = GPGME::Ctx.gpgcli_expect("--edit-key '#{self.fingerprint}' passwd") do |line|
        case line
        when /BAD_PASSPHRASE/
          [false, 'bad passphrase']
        when /change_passwd.empty.okay/
          'y'
        when /keyedit.prompt/
          "save"
        when /USERID_HINT|NEED_PASSPHRASE|GOT_IT|GOOD_PASSPHRASE|MISSING_PASSPHRASE|KEY_CONSIDERED|INQUIRE_MAXLEN|PROGRESS/
          nil
        else
          [false, "Unexpected line: #{line}"]
        end
      end
      # gpg-agent terminates itself if its socket goes away.
      delete_gpg_agent_socket
      delete_file(gpg_agent_log)

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
    def delete_gpg_agent_socket
      delete_file(ENV['GNUPGHOME'], 'S.gpg-agent')
    end

    # This method can be deleted once we cease to support gnupg 2.0.
    def delete_file(*args)
      path = File.join(Array(args))
      if File.exist?(path)
        File.delete(path)
      end
    end
  end
end
