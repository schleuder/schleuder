module Schleuder
  module Filters
    def self.send_key(list, mail)
      return if ! mail.sendkey_request?

      list.logger.debug "Sending public key as reply."

      out = mail.reply
      out.from = list.email
      # We're not sending to a subscribed address, so we need to specify a return-path manually.
      out.return_path = list.bounce_address
      out.body = I18n.t(:list_public_key_attached)
      # TODO: clean this up, there must be an easier way to attach inline-disposited content.
      filename = "#{list.email}.asc"
      out.add_file({
        filename: filename,
        content: list.export_key
      })
      out.attachments[filename].content_type = 'application/pgp-keys'
      out.attachments[filename].content_description = 'OpenPGP public key'
      # TODO: find out why the gpg-module puts all the headers into the first mime-part, too
      out.gpg sign: true
      out.deliver
      exit
    end
  end
end
