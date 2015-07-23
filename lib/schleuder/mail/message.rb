module Mail
  # TODO: Test if subclassing breaks integration of mail-gpg.
  class Message
    attr_accessor :recipient
    attr_writer :was_encrypted

    # TODO: This should be in initialize(), but I couldn't understand the
    # strange errors about wrong number of arguments when overriding
    # Message#initialize.
    def setup(recipient)
      if self.encrypted?
        new = self.decrypt(verify: true)
        new.was_encrypted = true
      elsif self.signed?
        new = self.verify
      else
        new = self
      end

      new.recipient = recipient
      new
    end

    def clean_copy(list, with_pseudoheaders=false)
      clean = Mail.new
      clean.from = list.email
      clean.subject = self.subject
      clean.return_path = list.email.gsub(/@/, '-owner@')

      if list.keep_msgid
        clean['In-Reply-To'] = self.header['in-reply-to']
        clean['Message-ID'] = self.header['Message-ID']
        clean.references = self.references
      end

      if with_pseudoheaders
        new_part = Mail::Part.new
        new_part.body = self.pseudoheaders
        clean.add_part new_part
      end

      # Attach body or mime-parts, respectively.
      if self.multipart?
        self.parts.each do |part|
          clean.add_part Mail::Part.new(part)
        end
      else
        clean.add_part Mail::Part.new(self.body)
      end
      clean
    end

    def prepend_part(part)
      self.add_part(part)
      self.parts.unshift(parts.delete_at(parts.size-1))
    end

    def was_encrypted?
      @was_encrypted
    end

    def signature
      # Is there any theoretical case in which there's more than one signature?
      signatures.try(:first)
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
      reply = self.reply
      reply.body = output
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
          command = $1.strip.downcase
          arguments = $2.to_s.strip.downcase.split(/[,; ]{1,}/)
          @keywords << [command, arguments]
          nil
        else
          line
        end
      end.compact.join

      @keywords
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

    def standard_pseudoheaders(list)
      if @standard_pseudoheaders.present?
        return @standard_pseudoheaders
      else
        @standard_pseudoheaders = []
      end

      Array(list.headers_to_meta).each do |field|
        @standard_pseudoheaders << make_pseudoheader(field.to_s, self.header[field.to_s])
      end

      # Careful to add information about the incoming signature. GPGME throws
      # exceptions if it doesn't know the key.
      if self.signature.present?
        msg = begin
                self.signature.to_s
              rescue EOFError
                "Unknown signature by #{self.signature.fpr}"
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

    def pseudoheaders(list)
      (standard_pseudoheaders(list) + dynamic_pseudoheaders).flatten.join("\n") + "\n"
    end

  end
end
