require 'schleuder/mail/gpg/verified_part'

# decryption of the so called 'PGP-Inline' message types
# this is not a standard, so the implementation is based on the notes
# here http://binblog.info/2008/03/12/know-your-pgp-implementation/
# and on test messages generated with the Mozilla Enigmail OpenPGP
# plugin https://www.enigmail.net
module Mail
  module Gpg
    class InlineDecryptedMessage < Mail::Message

      # options are:
      #
      # :verify: decrypt and verify
      def self.setup(cipher_mail, options = {})
        if cipher_mail.multipart?
          self.new do
            Mail::Gpg.copy_headers cipher_mail, self

            # Drop the HTML-part of a multipart/alternative-message if it is
            # inline-encrypted: that ciphertext is probably wrapped in HTML,
            # which GnuPG chokes upon, so we would have to parse the HTML to
            # handle the message-part properly.
            # Also it's not clear how to handle the resulting plain-text: is
            # it HTML or simple text?  That depends on the sending MUA and
            # the original input.
            # In summary, that's too much complications.
            if cipher_mail.mime_type == 'multipart/alternative' &&
                cipher_mail.html_part.present? &&
                cipher_mail.html_part.body.decoded.include?('-----BEGIN PGP MESSAGE-----')
              cipher_mail.parts.delete_if do |part|
                part[:content_type].content_type == 'text/html'
              end
              # Set the content-type of the newly generated message to
              # something less confusing.
              content_type 'multipart/mixed'
              # Leave a marker for other code.
              header['X-MailGpg-Deleted-Html-Part'] = 'true'
            end

            cipher_mail.parts.each do |part|
              p = VerifiedPart.new do |p|
                if part.has_content_type? && /application\/(?:octet-stream|pgp-encrypted)/ =~ part.mime_type
                  # encrypted attachment, we set the content_type to the generic 'application/octet-stream'
                  # and remove the .pgp/gpg/asc from name/filename in header fields
                  decrypted = GpgmeHelper.decrypt(part.decoded, options)
                  p.verify_result decrypted.verify_result if options[:verify]
                  p.content_type part.content_type.sub(/application\/(?:octet-stream|pgp-encrypted)/, 'application/octet-stream')
                    .sub(/name=(?:"')?(.*)\.(?:pgp|gpg|asc)(?:"')?/, 'name="\1"')
                  p.content_disposition part.content_disposition.sub(/filename=(?:"')?(.*)\.(?:pgp|gpg|asc)(?:"')?/, 'filename="\1"')
                  p.content_transfer_encoding Mail::Encodings::Base64
                  p.body Mail::Encodings::Base64::encode(decrypted.to_s)
                else
                  body = part.body.decoded
                  if body.include?('-----BEGIN PGP MESSAGE-----')
                    decrypted = GpgmeHelper.decrypt(body, options)
                    p.verify_result decrypted.verify_result if options[:verify]
                    p.body decrypted.to_s
                  else
                    p.content_type part.content_type
                    p.content_transfer_encoding part.content_transfer_encoding
                    p.body part.body.to_s
                  end
                end
              end
              add_part p
            end
          end # of multipart
        else
          decrypted = cipher_mail.body.empty? ? '' : GpgmeHelper.decrypt(cipher_mail.body.decoded, options)
          self.new do
            cipher_mail.header.fields.each do |field|
              header[field.name] = field.value
            end
            body decrypted.to_s
            verify_result decrypted.verify_result if options[:verify] && '' != decrypted
          end
        end
      end
    end
  end
end
