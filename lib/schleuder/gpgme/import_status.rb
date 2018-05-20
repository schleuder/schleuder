module GPGME
  class ImportStatus
    attr_reader :action

    # Unfortunately in initialize() @status and @result are not yet initialized.
    def set_action
      @action ||= if self.result > 0
                    # An error happened.
                    # TODO: Give details by going through the list of errors in
                    # "gpg-errors.h" and find out which is present here.
                    'error'
                  else
                    # TODO: refactor with Ctx#translate_import_data
                    case self.status
                    when 0
                      'unchanged'
                    when IMPORT_NEW
                      'imported'
                    else
                      'updated'
                    end
                  end
      self
    end

    # Force encoding, some databases save "ASCII-8BIT" as binary data.
    alias_method :orig_fingerprint, :fingerprint
    def fingerprint
      orig_fingerprint.encode(Encoding::US_ASCII)
    end

  end
end
