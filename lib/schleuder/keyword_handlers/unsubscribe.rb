module Schleuder
  module KeywordHandlers
    class Unsubscribe < Base
      handles_request_keyword :unsubscribe

      WANTED_ARGUMENTS = [Conf::EMAIL_REGEXP]

      def run(mail)
        # If no address was given we unsubscribe the sender.
        email = @arguments.first.to_s.downcase.presence || mail.signer.email

        subscription = subscriptions_controller.delete(mail.list.email, email)

        if subscription.destroyed?
          t('.unsubscribed', email: subscription.email)
        else
          t('unsubscribing_failed', email: subscription.email, error: subscription.errors.to_a)
        end
      end
    end
  end
end