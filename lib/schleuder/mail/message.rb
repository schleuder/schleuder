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

      clean.add_msgids(list, self)
      clean.add_list_headers(list)
      clean.add_openpgp_headers(list)

      if with_pseudoheaders
        new_part = Mail::Part.new
        new_part.body = self.pseudoheaders(list)
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
      # Theoretically there might be more than one signing key, in practice this is neglectable.
      signatures.try(:first)
    end

    def was_validly_signed?
      signature.present? && signature.valid? && signer.present?
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

    def bounce?
      @recipient.match(/-bounce@/) ||
          # Empty Return-Path
          self.return_path.to_s == '<>' ||
          # Auto-Submitted exists and does not equal 'no'
          ( self['Auto-Submitted'].present? && self['Auto-Submitted'].to_s.downcase != 'no' )
    end

    def keywords
      return @keywords if @keywords

      # Look only in first part of message.
      part = multipart? ?  parts.first : self

      # Parse only plain text for keywords.
      if part.mime_type != 'text/plain'
        Schleuder.logger.debug "First part of message is not text/plain, not collecting keywords"
        return []
      end

      # TODO: collect keywords while creating new mail as base for outgoing mails: that way we wouldn't need to change the body/part but rather filter the old body before assigning it to the new one. (And it helps also with having a distinct msg-id for all subscribers)

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

    def add_subject_prefix(string)
      if ! string.to_s.strip.empty?
        self.subject = "#{string} #{self.subject}"
      end
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

      # Careful to add information about the incoming signature. GPGME
      # throws exceptions if it doesn't know the key.
      if self.signature.present?
        msg = begin
                self.signature.to_s
              rescue EOFError
                "Unknown signature by 0x#{self.signature.fingerprint}"
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

    def add_msgids(list, orig)
      if list.keep_msgid
        self['In-Reply-To'] = orig.header['In-Reply-To']
        self['Message-ID'] = orig.header['Message-ID']
        self.references = orig.references
      end
    end

    def add_list_headers(list)
      if list.include_list_headers
        self['List-Id'] = "<#{list.email.gsub('@', '.')}>"
        self['List-Owner'] = "<mailto:#{list.owner_address}> (Use list's public key)"
        self['List-Help'] = '<https://schleuder2.nadir.org/>'

        postmsg = if list.receive_admin_only
                    "NO (Admins only)"
                  elsif list.receive_authenticated_only
                    "<mailto:#{list.email}> (Subscribers only)"
                  else
                    "<mailto:#{list.email}>"
                  end

        self['List-Post'] = postmsg
      end
    end

    def add_openpgp_headers(list)
      if list.include_openpgp_header

        if list.openpgp_header_preference == 'none'
          pref = ''
        else
          pref = "preference=#{list.openpgp_header_preference}"

          # TODO: simplify.
          pref << ' ('
          if list.receive_admin_only
            pref << 'Only encrypted and signed emails by list-admins are accepted'
          elsif ! list.receive_authenticated_only
            if list.receive_encrypted_only && list.receive_signed_only
              pref << 'Only encrypted and signed emails are accepted'
            elsif list.receive_encrypted_only && ! list.receive_signed_only
              pref << 'Only encrypted emails are accepted'
            elsif ! list.receive_encrypted_only && list.receive_signed_only
              pref << 'Only signed emails are accepted'
            else
              pref << 'All kind of emails are accepted'
            end
          elsif list.receive_authenticated_only
            if list.receive_encrypted_only
              pref << 'Only encrypted and signed emails by list-members are accepted'
            else
              pref << 'Only signed emails by list-members are accepted'
            end
          else
            pref << 'All kind of emails are accepted'
          end
          pref << ')'
        end

        fingerprint = list.key.fingerprint
        comment = "(Send an email to #{list.sendkey_address} to receive the public-key)"

        self['OpenPGP'] = "id=0x#{fingerprint} #{comment}; #{pref}"
      end
    end

  end
end
