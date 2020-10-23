module Schleuder
  module KeywordHandlers
    class ResendCcEncryptedOnly < Base
      include ResendingMixin

      handles_list_keyword 'resend-cc-encrypted-only', with_arguments: ONE_OR_MANY_EMAIL_ADDRS

      def run(mail)
        resend_it_cc(mail: mail, encrypted_only: true)
      end
    end
  end
end
