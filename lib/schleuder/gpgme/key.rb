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

    def adduid(uid, email)
      # This block can be deleted once we cease to support gnupg 2.0.
      if ! GPGME::Ctx.sufficient_gpg_version?('2.1.4')
        return adduid_expect(uid, email)
      end

      # Specifying the key via fingerprint apparently doesn't work.
      GPGME::Ctx.gpgcli("--quick-adduid #{uid} '#{uid} <#{email}>'")
    end

    # This method can be deleted once we cease to support gnupg 2.0.
    def adduid_expect(uid, email)
      GPGME::Ctx.gpgcli_expect("--allow-freeform-uid --edit-key '#{self.fingerprint}' adduid") do |line|
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
    end

  end
end
