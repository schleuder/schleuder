module Schleuder
  module KeywordHandlers
    class ResendUnencrypted < Base
      include ResendingMixins

      handles_list_keyword 'resend-unencrypted'

      WANTED_ARGUMENTS = ONE_OR_MANY_EMAIL_ADDRS

      def run(mail)
        do_resend_unencrypted(mail: mail, to_or_cc: :to)
      end
    end
  end
end
