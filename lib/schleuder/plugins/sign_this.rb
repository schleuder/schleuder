module Schleuder
  module RequestPlugins
    def self.sign_this(arguments, list, mail)
      if mail.parts.empty? && mail.body.to_s.present?
        # Single text/plain-output is handled by the plugin-runner well, we
        # don't need to take care of the reply.
        list.logger.debug "Clear-signing text/plain body"
        clearsign(mail)
      else
        # Here we need to send our reply manually because we're sending
        # attachments. Maybe move this ability into the plugin-runner?
        list.logger.debug "Signing each attachment's body"
        out = multipart(mail.reply, list, mail)
        list.logger.info "Replying directly to sender"
        reply(out)
        list.logger.info "Exiting."
        exit
      end
    end

    def self.multipart(out, list, mail)
      mail.parts.each do |part|
        next if part.body.to_s.strip.blank?
        file_basename = part.filename.presence || Digest::SHA256.hexdigest(part.body.to_s)
        list.logger.debug "Signing #{file_basename}"
        filename = "#{file_basename}.sig"
        out.add_file({
            filename: filename,
            content: detachsign(part.body.to_s)
          })
        out.attachments[filename].content_description = "OpenPGP signature for '#{file_basename}'"
      end
      out
    end

    def self.reply(out)
      out.from = list.email
      out.return_path = list.bounce_address
      out.body = I18n.t('plugins.signatures_attached')
      out.gpg sign: true, encrypt: true
      out.deliver
    end

    def self.sign_each_part(list, mail)
    end

    def self.detachsign(thing)
      crypto.sign(thing, mode: GPGME::SIG_MODE_DETACH).to_s
    end

    def self.clearsign(mail)
      return crypto.clearsign(mail.body.to_s).to_s
    end

    def self.crypto
      @crypto ||= GPGME::Crypto.new
    end
  end
end
