module Schleuder
  module KeywordHandlers
    class ResendCcUnencrypted < Base
      include ResendingMixin

      handles_list_keyword 'resend-cc-unencrypted', with_arguments: ONE_OR_MANY_EMAIL_ADDRS

      def run(mail)
        do_resend_unencrypted(mail: mail, to_or_cc: :cc)
      end
    end
  end
end
