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

    # Force encoding, some databases save "ASCII-8BIT" as binary data.
    alias_method :orig_fingerprint, :fingerprint
    def fingerprint
      orig_fingerprint.encode(Encoding::US_ASCII)
    end

    def adduid(uid, newuid, homedir)
      output = ''
      exitcode = -1
      # Specifying the key via fingerprint apparently doesn't work.
      cmd = "gpg --homedir '#{homedir}' --quick-adduid #{uid} '#{uid} <#{newuid}>'"
      Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
        output = stdout_err.readlines.join
        exitcode = wait_thr.value
      end

      [exitcode.to_i, output.to_s]
    end
  end
end
