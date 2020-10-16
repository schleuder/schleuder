module Schleuder
  module KeywordHandlers
    class Resend < Base
      include ResendingMixin

      handles_list_keyword 'resend'

      WANTED_ARGUMENTS = ONE_OR_MANY_EMAIL_ADDRS

      def run(mail)
        resend_it(mail: mail, encrypted_only: false)
      end
    end
  end
end
