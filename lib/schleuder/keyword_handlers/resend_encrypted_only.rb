module Schleuder
  module KeywordHandlers
    class ResendEncryptedOnly < Base
      include ResendingMixin

      handles_list_keyword 'resend-encrypted-only', with_arguments: ONE_OR_MANY_EMAIL_ADDRS

      def run
        return if ! may_resend_encrypted?(@mail)
        resend_it(mail: @mail, encrypted_only: true)
      end
    end
  end
end
