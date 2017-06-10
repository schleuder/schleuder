module Mail
  # TODO: Test if subclassing breaks integration of mail-gpg.
  class Message
    attr_accessor :recipient
    attr_accessor :original_message
    attr_accessor :list

    # TODO: This should be in initialize(), but I couldn't understand the
    # strange errors about wrong number of arguments when overriding
    # Message#initialize.
    def setup(recipient, list)
      if self.encrypted?
        new = self.decrypt(verify: true)
        ## Work around a bug in mail-gpg: when decrypting pgp/mime the
        ## Date-header is not copied.
        #new.date ||= self.date
        # Test if there's a signed multipart inside the ciphertext
        # ("encapsulated" format of pgp/mime).
        if new.signed?
          new = new.verify
        end
      elsif self.signed?
        new = self.verify
      else
        new = self
      end

      new.list = list
      new.gpg list.gpg_sign_options
      new.original_message = self.dup.freeze
      new.recipient = recipient
      # Trigger method early to save the information. Later some information
      # might be gone (e.g. request-keywords that delete subscriptions or
      # keys).
      new.signer
      new
    end

    def clean_copy(with_pseudoheaders=false)
      clean = Mail.new
      clean.list = self.list
      clean.gpg self.list.gpg_sign_options
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

      # Attach body or mime-parts in a new wrapper-part, to preserve the
      # original mime-structure.
      # We can't use self.to_s here — that includes all the headers we *don't*
      # want to copy.
      wrapper_part = Mail::Part.new
      # Copy headers to are relevant for the mime-structure.
      wrapper_part.content_type = self.content_type
      wrapper_part.content_transfer_encoding = self.content_transfer_encoding if self.content_transfer_encoding
      wrapper_part.content_disposition = self.content_disposition if self.content_disposition
      wrapper_part.content_description = self.content_description if self.content_description
      # Copy contents.
      if self.multipart?
        self.parts.each do |part|
          wrapper_part.add_part(part)
        end
      else
        # We copied the content-headers, so we need to copy the body encoded.
        # Otherwise the content might become unlegible.
        wrapper_part.body = self.body.encoded
      end
      clean.add_part(wrapper_part)

      clean
    end

    def prepend_part(part)
      self.add_part(part)
      self.parts.unshift(parts.delete_at(parts.size-1))
    end

    def add_footer!
      # Add public_footer unless it's empty?.
      if self.list.present? && ! self.list.public_footer.to_s.strip.empty?
        footer_part = Mail::Part.new
        footer_part.body = list.public_footer.strip
        if parts.size == 1 && parts.first.mime_type == 'multipart/mixed' && parts.first.parts.size == 1 && parts.first.parts.first.mime_type == 'text/plain'
          self.parts.first.add_part footer_part
        else
          self.add_part footer_part
        end
      end
    end

    def was_encrypted?
      Mail::Gpg.encrypted?(original_message)
    end

    def signature
      case signatures.size
      when 0
        if multipart?
          signature_multipart_inline
        else
          nil
        end
      when 1
        signatures.first
      else
        raise "Multiple signatures found! Cannot handle!"
      end
    end

    def was_validly_signed?
      signature.present? && signature.valid? && signer.present?
    end

    def signer
      @signer ||= begin
        if signing_key.present?
          list.subscriptions.where(fingerprint: signing_key.fingerprint).first
        end
      end
    end

    # The fingerprint of the signature might be the one of a sub-key, but the
    # subscription-assigned fingerprints are (should be) the ones of the
    # primary keys, so we need to look up the key.
    def signing_key
      if signature.present?
        @signing_key ||= list.all_keys(signature.fpr).first
      end
    end

    def reply_to_signer(output)
      reply = self.reply
      self.class.all_to_message_part(output).each do |part|
        reply.add_part(part)
      end
      self.signer.send_mail(reply)
    end

    def self.all_to_message_part(input)
      Array(input).map do |thing|
        case thing
        when Mail::Part
          thing
        when String
          Mail::Part.new do
            body thing.to_s
          end
        else
          raise "Don't know how to handle input: #{thing.inspect}"
        end
      end
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

    def automated_message?
      @recipient.match(/-bounce@/).present? ||
          # Empty Return-Path
          self.return_path.to_s == '<>' ||
          # Auto-Submitted exists and does not equal 'no'
          ( self['Auto-Submitted'].present? && self['Auto-Submitted'].to_s.downcase != 'no' )
    end

    def keywords
      return @keywords if @keywords

      part = first_plaintext_part
      if part.blank?
        return []
      end

      @keywords = []
      part.body = part.decoded.lines.map.with_index do |line, i|
        # Break after some lines to not run all the way through maybe huge emails.
        if i > 1000
          break
        end
        # TODO: Find multiline arguments (add-key). Currently add-key has to
        # read the whole body and hope for the best.
        if line.match(/^x-([^:\s]*)[:\s]*(.*)/i)
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

    def add_subject_prefix!
      _add_subject_prefix(nil)
    end

    def add_subject_prefix_in!
      _add_subject_prefix(:in)
    end

    def add_subject_prefix_out!
      _add_subject_prefix(:out)
    end

    def add_pseudoheader(key, value)
      @dynamic_pseudoheaders ||= []
      @dynamic_pseudoheaders << make_pseudoheader(key, value)
    end

    def make_pseudoheader(key, value)
      "#{key.to_s.camelize}: #{value.to_s}"
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
        # Some versions of gpgme return nil if the key is unknown, so we check
        # for that manually and provide our own fallback. (Calling
        # `signature.key` results in an EOFError in that case.)
        if signing_key.present?
          msg = signature.to_s
        else
          # TODO: I18n
          msg = "Unknown signature by unknown key 0x#{self.signature.fingerprint}"
        end
      else
        # TODO: I18n
        msg = "Unsigned"
      end
      @standard_pseudoheaders << make_pseudoheader(:sig, msg)

      # TODO: I18n
      @standard_pseudoheaders << make_pseudoheader(
            :enc,
            was_encrypted? ? 'Encrypted' : 'Unencrypted'
        )

      @standard_pseudoheaders
    end

    def pseudoheaders(list)
      (standard_pseudoheaders(list) + dynamic_pseudoheaders).flatten.join("\n") + "\n"
    end

    def add_msgids(list, orig)
      if list.keep_msgid
        # Don't use `orig['in-reply-to']` here, because that sometimes fails to
        # parse the original value and then returns it without the
        # angle-brackets.
        self.message_id = clutch_anglebrackets(orig.message_id)
        self.in_reply_to = clutch_anglebrackets(orig.in_reply_to)
        self.references = clutch_anglebrackets(orig.references)
      end
    end

    def add_list_headers(list)
      if list.include_list_headers
        self['List-Id'] = "<#{list.email.gsub('@', '.')}>"
        self['List-Owner'] = "<mailto:#{list.owner_address}> (Use list's public key)"
        self['List-Help'] = '<https://schleuder.nadir.org/>'

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
              pref << 'Only encrypted and signed emails by subscribers are accepted'
            else
              pref << 'Only signed emails by subscribers are accepted'
            end
          else
            pref << 'All kind of emails are accepted'
          end
          pref << ')'
        end

        fingerprint = list.fingerprint
        comment = "(Send an email to #{list.sendkey_address} to receive the public-key)"

        self['OpenPGP'] = "id=0x#{fingerprint} #{comment}; #{pref}"
      end
    end

    def empty?
      if self.multipart?
        if self.parts.empty?
          return true
        else
          # Test parts recursively. E.g. Thunderbird with activated
          # memoryhole-headers send nested parts that might still be empty.
          return parts.inject(true) { |result, part| result && part.empty? }
        end
      else
        return self.body.empty?
      end
    end

    def first_plaintext_part(part=nil)
      part ||= self
      if part.multipart?
        first_plaintext_part(part.parts.first)
      elsif part.mime_type == 'text/plain'
        part
      else
        nil
      end
    end


    def attach_list_key!(list)
      filename = "#{list.email}.asc"
      self.add_file({
        filename: filename,
        content: list.export_key
      })
      self.attachments[filename].content_type = 'application/pgp-keys'
      self.attachments[filename].content_description = 'OpenPGP public key'
      true
    end

    private


    def _add_subject_prefix(suffix)
      attrib = "subject_prefix"
      if suffix
        attrib << "_#{suffix}"
      end
      if ! self.list.respond_to?(attrib)
        return false
      end

      string = self.list.send(attrib).to_s.strip
      if ! string.empty?
        prefix = "#{string} "
        # Only insert prefix if it's not present already.
        if ! self.subject.include?(prefix)
          self.subject = "#{string} #{self.subject}"
        end
      end
    end

    # Looking for signatures in each part. They are not aggregated into the main part.
    # We only return the signature if all parts are validly signed by the same key.
    def signature_multipart_inline
      fingerprints = parts.map do |part|
        if part.signature_valid?
          part.signature.fpr
        else
          nil
        end
      end
      if fingerprints.uniq.size == 1
        parts.first.signature
      else
        nil
      end
    end

    def clutch_anglebrackets(input)
      Array(input).map do |string|
        if string.first == '<'
          string
        else
          "<#{string}>"
        end
      end.join(' ')
    end
  end
end
