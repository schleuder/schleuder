module Schleuder
  module KeywordHandlers
    class Resend < Base
      include ResendingMixin

      handles_list_keyword 'resend', with_arguments: ONE_OR_MANY_EMAIL_ADDRS

      def run
        if @arguments.blank?
          if @invalid_arguments.any?
            @invalid_arguments.each do |invalid_argument|
              @mail.add_pseudoheader(:error, I18n.t('keyword_handlers.resend.invalid_recipient', address: invalid_argument))
            end
          else
            @mail.add_pseudoheader(:error, I18n.t('keyword_handlers.resend.invalid_recipient', address: ''))
          end
        else
          resend_it(mail: @mail, encrypted_only: false)
        end
      end
    end
  end
end
