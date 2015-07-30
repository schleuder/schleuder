module GPGME
  class ImportStatus
    def action
      case status
      when 0 then "unchanged"
      when 1 then "imported"
      else "updated"
      end
    end

    # Force encoding, some databases save "ASCII-8BIT" as binary data.
    alias_method :orig_fingerprint, :fingerprint
    def fingerprint
      orig_fingerprint.encode(Encoding::US_ASCII)
    end

  end
end
