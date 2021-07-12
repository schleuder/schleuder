module Mail
  module Gpg
    class SignPart < Mail::Part
      # Copied verbatim from mail-gpg v.0.4.2. This code was changed in
      # <https://github.com/jkraemer/mail-gpg/commit/5fded41ccee4a58f848a2f8e7bd53d11236f8984>,
      # which breaks verifying some encapsulated (signed-then-encrypted)
      # messages. See
      # <https://github.com/jkraemer/mail-gpg/pull/40#issue-95776382> for
      # details.
      def self.verify_signature(plain_part, signature_part, options = {})
        if !(signature_part.has_content_type? &&
            ('application/pgp-signature' == signature_part.mime_type))
          return false
        end

        # Work around the problem that plain_part.raw_source prefixes an
        # erroneous CRLF, <https://github.com/mikel/mail/issues/702>.
        if ! plain_part.raw_source.empty?
          plaintext = [ plain_part.header.raw_source,
                        "\r\n\r\n",
                        plain_part.body.raw_source
          ].join
        else
          plaintext = plain_part.encoded
        end

        signature = signature_part.body.encoded
        GpgmeHelper.sign_verify(plaintext, signature, options)
      end
    end
  end
end

