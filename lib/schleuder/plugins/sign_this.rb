module Schleuder
  module RequestPlugins
    def self.sign_this(arguments, list, mail)
      if mail.has_attachments?
        # Here we need to send our reply manually because we're sending
        # attachments.
        # TODO: Maybe move this ability into the plugin-runner?
        reply_msg = sign_attachments(mail.reply, list, mail)
        reply_msg.body = I18n.t('plugins.signatures_attached')
        list.logger.info "Replying directly to sender"
        mail.signer.send_mail(reply_msg)
        list.logger.info "Exiting."
        exit
      else
        # Single text/plain-output is handled by the plugin-runner well, we
        # don't need to take care of the reply.
        list.logger.debug "Clear-signing first available text/plain part"
        clearsign(mail.first_plaintext_part)
      end
    end

    def self.sign_attachments(reply_msg, list, mail)
      list.logger.debug "Signing each attachment's body"
      mail.attachments.each do |attachment|
        material = attachment.body.to_s
        next if material.strip.blank?
        file_basename = attachment.filename.presence || Digest::SHA256.hexdigest(material)
        list.logger.debug "Signing #{file_basename}"
        filename = "#{file_basename}.sig"
        reply_msg.add_file({
            filename: filename,
            content: detachsign(material)
          })
        reply_msg.attachments[filename].content_description = "OpenPGP signature for '#{file_basename}'"
      end
      reply_msg
    end

    def self.detachsign(thing)
      crypto.sign(thing, mode: GPGME::SIG_MODE_DETACH).to_s
    end

    def self.clearsign(mail)
      crypto.clearsign(mail.body.to_s).to_s
    end

    def self.crypto
      @crypto ||= GPGME::Crypto.new
    end
  end
end
