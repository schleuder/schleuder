module Schleuder
  module KeywordHandlers
    class ListSubscriptions < Base
      handles_request_keyword 'list-subscriptions'

      WANTED_ARGUMENTS = [/\S*/]


      def run(mail)
        subscriptions = subscriptions_controller.find_all(mail.list.email).to_a

        if @arguments.present?
          regexp = Regexp.new(@arguments)
          subscriptions.select! do |subscription|
            subscription.email.match(regexp)
          end
        end

        if subscriptions.blank?
          return I18n.t(:no_output_result)
        end

        out = [ t('list_of_subscriptions') ]

        out << subscriptions.map do |subscription|
          # Fingerprints are at most 40 characters long, and lines shouldn't
          # exceed 80 characters if possible.
          line = subscription.email
          if subscription.fingerprint.present?
            line << "\t0x#{subscription.fingerprint}"
          end
          if ! subscription.delivery_enabled?
            line << "\tDelivery disabled!"
          end
          line
        end

        out.join("\n")
      end
    end
  end
end