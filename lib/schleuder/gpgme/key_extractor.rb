module GPGME
  class KeyExtractor
    # This takes key material and returns those keys from it, that have a UID
    # matching the given email address, stripped by all other UIDs.
    def self.extract_by_email_address(email_address, keydata)
      orig_gnupghome = ENV['GNUPGHOME']
      ENV['GNUPGHOME'] = Dir.mktmpdir
      gpg = GPGME::Ctx.new(armor: true)
      gpg_arg = %{ --import-filter keep-uid='mbox = #{email_address}'}
      gpg.import_filtered(keydata, gpg_arg)
      # Return the fingerprint and the exported, filtered keydata, because
      # passing the key objects around led to strange problems with some keys,
      # which produced only a blank string as return value of export().
      result = {}
      gpg.keys.each do |tmp_key|
        # Skip this key if it has
        # * no UID – because none survived the import-filter,
        # * more than one UID – which means the import-filtering failed or
        #   something else went wrong during import.
        if tmp_key.uids.size == 1
          result[tmp_key.fingerprint] = tmp_key.armored
        end
      end
      result
    ensure
      FileUtils.rm_rf(ENV['GNUPGHOME'], secure: true)
      ENV['GNUPGHOME'] = orig_gnupghome
    end
  end
end
