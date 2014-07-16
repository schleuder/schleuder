module Mail
  # TODO: Test if subclassing breaks integration of mail-gpg.
  class Message
    attr_accessor :recipient
    attr_writer :was_encrypted

    # TODO: This should be in initialize(), but I couldn't understand the
    # strange errors about wrong number of arguments when overriding
    # Message#initialize.
    def setup(recipient)

      # TODO: Msg-ID
      if self.encrypted?
        new = self.decrypt(verify: true)
        new.was_encrypted = true
      elsif self.signed?
        # Note: "inline"-signatures are not (yet?) supported by mail-gpg, so
        # they're not supported here, neither.
        # This triggeres the validation.
        self.signature_valid?
        # Code from Mail::Gpg.decrypt_pgp_mime()
        new = Mail.new(self.parts.first)
        %w(from to cc bcc date subject reply_to in_reply_to references).each do |field|
          new.send field, self.send(field)
        end
        new.verify_result = self.verify_result
      else
        new = self
      end

      new.recipient = recipient
      new
    end

    def clean_copy(list, with_pseudoheaders=false)
      new = Mail.new
      new.from = list.email
      new.subject = self.subject
      new['In-Reply-To'] = self.header['in-reply-to']
      new.references = self.references
      # TODO: attachments

      if with_pseudoheaders
        new_part = Mail::Part.new
        new_part.body = self.pseudoheaders
        new.add_part new_part
      end
      new.add_part Mail::Part.new(self)
      new
    end

    def was_encrypted?
      @was_encrypted
    end

    def signature
      # Is there any theoretical case in which there's more than one signature?
      verify_result.try(:signatures).try(:first)
    end

    def was_validly_signed?
      signature.valid? && signer.present?
    end

    def signer
      if fingerprint = self.signature.try(:fpr)
        Subscription.where(fingerprint: fingerprint).first
      end
    end

    def reply_to_signer(output)
      # TODO: catch unknown signatures earlier, those are invalid requests
      reply = self.reply
      reply.body = output(output)
      self.signer.send_mail(reply)
    end

    def sendkey_request?
      @recipient.match(/-sendkey@/)
    end

    def to_owner?
      @recipient.match(/-owner@/)
    end

    def request?
      @recipient.match(/-request@/)
    end

    def keywords
      return @keywords if @keywords

      # Parse only plain text for keywords.
      return [] if mime_type != 'text/plain'

      # TODO: collect keywords while creating new mail as base for outgoing mails: that way we wouldn't need to change the body/part but rather filter the old body before assigning it to the new one. (And it helps also with having a distinct msg-id for all subscribers)

      # Look only in first part of message.
      part = multipart? ?  parts.first : self
      @keywords = []
      part.body = part.decoded.lines.map do |line|
        # TODO: find multiline arguments (add-key)
        # TODO: break after some data to not parse huge amounts
        if line.match(/^x-([^: ]*)[: ]*(.*)/i)
          @keywords << [$1.strip.downcase, $2.strip.downcase]
          nil
        else
          line
        end
      end.compact.join

      @keywords
    end

    def reply_sendkey(list)
      out = self.reply
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
      out
    end

    def add_pseudoheader(key, value)
      @dynamic_pseudoheaders ||= []
      @dynamic_pseudoheaders << make_pseudoheader(key, value)
    end

    def make_pseudoheader(key, value)
      "#{key.to_s.capitalize}: #{value.to_s}"
    end

    def dynamic_pseudoheaders
      @dynamic_pseudoheaders || []
    end

    def standard_pseudoheaders
      if @standard_pseudoheaders.present?
        return @standard_pseudoheaders
      else
        @standard_pseudoheaders = []
      end

      %w[from to date cc].each do |field|
        @standard_pseudoheaders << make_pseudoheader(field, self.header[field])
      end

      # Careful to add information about the incoming signature. GPGME throws
      # exceptions if it doesn't know the key.
      if self.verify_result && self.verify_result.signatures.present?
        sig = self.verify_result.signatures.first
        msg = begin
                sig.to_s
              rescue EOFError
                "Unknown signature by #{sig.fpr}"
              end
      else
        msg = "Unsigned"
      end
      @standard_pseudoheaders << make_pseudoheader(:sig, msg)

      @standard_pseudoheaders << make_pseudoheader(
            :enc,
            was_encrypted? ? 'encrypted' : 'unencrypted'
        )

      @standard_pseudoheaders
    end

    def pseudoheaders
      (standard_pseudoheaders + dynamic_pseudoheaders).flatten.join("\n")
    end

  end
end
