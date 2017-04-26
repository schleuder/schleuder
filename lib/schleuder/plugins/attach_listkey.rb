module Schleuder
  module ListPlugins
    def self.attach_listkey(arguments, list, mail)
      filename = "#{list.fingerprint}.pgpkey"
      # "Mail" only really converts to multipart if the content-type is blank.
      mail.content_type = nil
      mail.add_file({
        filename: filename,
        content: list.export_key
      })
      mail.attachments[filename].content_type = 'application/pgp-keys'
      mail.attachments[filename].content_description = "OpenPGP public key of #{list.email}"
      mail.attachments[filename].content_disposition = "attachment; filename=#{filename}"
      nil
    end
  end
end
