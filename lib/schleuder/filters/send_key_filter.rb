module Schleuder
  module Filters
    def self.send_key(list, mail)
      return if ! mail.sendkey_request?

      list.logger.debug "Sending public key as reply."

      out = mail.reply
      out.from = list.email
      out.body = list.key.to_s
      # TODO: clean this up, there must be an easier way to attach inline-disposited content.
      filename = "#{list.email}.asc"
      out.add_file({
        filename: filename,
        content: list.armored_key.to_s
      })
      out.attachments[filename].content_disposition = 'inline'
      out.attachments[filename].content_description = 'OpenPGP public key'
      # TODO: find out why the gpg-module puts all the headers into the first mime-part, too
      out.gpg sign: true
      out.deliver
      exit
    end
  end
end
