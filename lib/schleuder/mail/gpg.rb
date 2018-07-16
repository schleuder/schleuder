module Mail
  module Gpg
    class << self  
      alias_method :encrypt_mailgpg, :encrypt

      def encrypt(cleartext_mail, options={})
        encrypted_mail = encrypt_mailgpg(cleartext_mail, options)
        if cleartext_mail.protected_headers_subject
          encrypted_mail.subject = cleartext_mail.protected_headers_subject
        end
        encrypted_mail
      end
    end  
  end
end
