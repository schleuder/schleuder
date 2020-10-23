module Schleuder
  module KeywordHandlers
    class ResendUnencrypted < Base
      include ResendingMixin

      handles_list_keyword 'resend-unencrypted', with_arguments: ONE_OR_MANY_EMAIL_ADDRS

      def run(mail)
        do_resend_unencrypted(mail: mail, to_or_cc: :to)
      end
    end
  end
end
