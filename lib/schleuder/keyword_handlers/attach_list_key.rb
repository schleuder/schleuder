module Schleuder
  module KeywordHandlers
    class AttachListKey < Base
      handles_list_keyword 'attach-listkey'
      handles_list_keyword 'attach-list-key'

      WANTED_ARGUMENTS = []

      # No need to authorize: there is no way to block a list from answering to
      # emails addressed to listname-sendkey@hostname, so we don't need a way
      # to block using this keyword.
      def run(mail)
        filename = "#{mail.list.fingerprint}.pgpkey"
        # "Mail" only really converts to multipart if the content-type is blank.
        mail.content_type = nil
        mail.add_file({
          filename: filename,
          content: mail.list.export_key
        })
        mail.attachments[filename].content_type = 'application/pgp-keys'
        mail.attachments[filename].content_description = "OpenPGP public key of #{mail.list.email}"
        mail.attachments[filename].content_disposition = "attachment; filename=#{filename}"
        nil
      end
    end
  end
end
