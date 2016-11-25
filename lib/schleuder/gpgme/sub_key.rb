module GPGME
  class SubKey
    # Overwrite to specify the full fingerprint instead of the short key-ID.
    def to_s
      sprintf("%s   %4d%s/%s %s\n",
              secret? ? 'ssc' : 'sub',
              length,
              pubkey_algo_letter,
              fingerprint,
              timestamp.strftime('%Y-%m-%d'))
    end
  end
end
