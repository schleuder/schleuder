module Schleuder
  module KeywordHandlers
    class ResendCc < Base
      include ResendingMixins

      handles_list_keyword 'resend-cc'

      WANTED_ARGUMENTS = ONE_OR_MANY_EMAIL_ADDRS

      def run(mail)
        resend_it_cc(mail: mail, encrypted_only: false)
      end
    end
  end
end
