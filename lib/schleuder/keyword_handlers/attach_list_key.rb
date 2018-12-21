module Schleuder
  module KeywordHandlers
    class AttachListKey < Base
      handles_list_keyword 'attach-listkey', with_method: :attach_list_key

      # No need to authorize: there is no way to block a list from answering to
      # emails addressed to listname-sendkey@hostname, so we don't need a way
      # to block using this keyword.
      def attach_list_key
        filename = "#{@list.fingerprint}.pgpkey"
        # "Mail" only really converts to multipart if the content-type is blank.
        @mail.content_type = nil
        @mail.add_file({
          filename: filename,
          content: @list.export_key
        })
        @mail.attachments[filename].content_type = 'application/pgp-keys'
        @mail.attachments[filename].content_description = "OpenPGP public key of #{@list.email}"
        @mail.attachments[filename].content_disposition = "attachment; filename=#{filename}"
        nil
      end
    end
  end
end
