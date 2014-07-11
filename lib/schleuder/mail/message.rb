module Mail
  # TODO: Test if subclassing breaks integration of mail-gpg.
  class Message
    attr_reader :recipient

    # TODO: Fix strange errors about wrong number of arguments when
    # overriding Message#initialize.
    def setup(recipient)
      @recipient = recipient
      @orig_message = self.dup

      if self.encrypted?
        # TODO: fix
        self.decrypt(verify: true)
      elsif self.signed?
        # TODO: test/fix
        self.verify!
      end
    end

    def signature
      verify_result.try(:signatures).try(:first)
    end

    def validly_signed?
      signer.present?
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
      @keywords ||= begin
        # Parse only plain text for keywords.
        return [] if mime_type != 'text/plain'

        # TODO: collect keywords while creating new mail as base for outgoing mails: that way we wouldn't need to change the body/part but rather filter the old body before assigning it to the new one. (And it helps also with having a distinct msg-id for all subscribers)

        # Look only in first part of message.
        part = multipart? ?  parts.first : body
        part = part.lines.map do |line|
          # TODO: find multiline arguments (add-key)
          # TODO: break after some data to not parse huge amounts
          if line.match(/^x-([^: ]*)[: ]*(.*)/i)
            @keywords << {$1.strip.downcase => $2.strip.downcase}
            nil
          else
            line
          end
        end.compact.join("\n")
      end
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

    def clean_copy(list)
      new = Mail.new
      new.from = list.email
      new.subject = self.subject
      new['in-reply-to'] = self.header['in-reply-to']
      new.references =  self.references
      # TODO: attachments
      
      # Insert Meta-Headers
      # TODO: why is :date blank?
      meta = [
        "From: #{self.header[:from].to_s}",
        "To: #{self.header[:to].to_s}",
        "Date: #{self.header[:date].to_s}",
        "Cc: #{self.header[:cc].to_s}"
      ]

      # Careful to add information about the incoming signature. GPGME throws
      # exceptions if it doesn't know the key.
      if result = self.verify_result
        sig = self.verify_result.signatures.first
        msg = begin
                sig.to_s
              rescue EOFError
                "Unknown signature by #{sig.fpr}"
              end
      else
        msg = "Unsigned"
      end
      meta << "Sig: #{msg}"
      # TODO: Enc:

      new.add_part Mail::Part.new() { body meta.join("\n") }
      new.add_part Mail::Part.new(self.raw_source)
      new
    end
  end
end
