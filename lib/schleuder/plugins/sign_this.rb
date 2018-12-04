module Schleuder
  module RequestPlugins
    def self.sign_this(arguments, list, mail)
      if mail.has_attachments?
        list.logger.debug "Signing each attachment's body"
        intro = I18n.t('plugins.signatures_attached')
        parts = mail.attachments.map do |attachment|
          make_signature_part(attachment, list)
        end
        [intro, parts].flatten
      elsif arguments.present? && arguments != ['']
        list.logger.debug 'Clear-signing given arguments'
        clearsign(arguments.join("\n"))
      else
        list.logger.debug 'Clear-signing first available text/plain part'
        clearsign(mail.first_plaintext_part.body.to_s)
      end
    end

    # helper methods
    private

    def self.make_signature_part(attachment, list)
      material = attachment.body.to_s
      return nil if material.strip.blank?
      file_basename = attachment.filename.presence || Digest::SHA256.hexdigest(material)
      list.logger.debug "Signing #{file_basename}"
      filename = "#{file_basename}.sig"
      part = Mail::Part.new
      part.body = detachsign(material)
      part.content_type = 'application/pgp-signature'
      part.content_disposition = "attachment; filename=#{filename}"
      part.content_description = "OpenPGP signature for '#{file_basename}'"
      part
    end

    def self.detachsign(thing)
      crypto.sign(thing, mode: GPGME::SIG_MODE_DETACH).to_s
    end

    def self.clearsign(string)
      crypto.clearsign(string.to_s).to_s
    end

    def self.crypto
      @crypto ||= GPGME::Crypto.new(armor: true)
    end
  end
end
