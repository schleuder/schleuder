module Schleuder
  module Filters
    def self.key_auto_import_from_autocrypt_header(list, mail)
      if list.key_auto_import_from_email
        EmailKeyImporter.import_from_autocrypt_header(list, mail)
      end
    end
  end
end
