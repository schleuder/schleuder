module Schleuder
  module KeywordHandlers
    class Subscribe < Base
      handles_request_keyword :subscribe
      handles_request_keyword 'add-member' # Example of an alias

      # This method returns the collected arguments as second return value so
      # the actual method doesn't have to check for a space-delimited
      # fingerprint again.
      def validate_arguments(arguments)
        return :more if arguments.blank?

        email = arguments.shift.downcase
        if ! email.match(Conf::EMAIL_REGEXP)
          raise "Error: Keyword 'subscribe' needs a valid email address as first argument."
        end

        if arguments.blank?
          return :more, [email]
        end

        # Collect all arguments that look like fingerprint-material
        fingerprint = ''
        while arguments.first.present? && arguments.first.match(/^(0x)?[a-f0-9]+$/i)
          fingerprint << arguments.shift.downcase
        end

        if ! fingerprint.match(Conf::FINGERPRINT_REGEXP)
          return :invalid
        end

        if arguments.blank?
          return :more, [email, fingerprint]
        end

        adminflag = arguments.shift.downcase.presence
        if ! %[true false].include?(adminflag)
          return :invalid
        end

        if arguments.blank?
          return :more, [email, fingerprint, adminflag]
        end

        delivery_enabled = arguments.shift.downcase.presence
        if ! %[true false].include?(delivery_enabled)
          return :invalid
        end

        if arguments.any?
          return :invalid
        end

        return :end, [email, fingerprint, adminflag, delivery_enabled]
      end

      def run(mail)
        if @arguments.blank?
          return t('subscribe_requires_arguments')
        end

        subscription_params = {}
        subscription_params['email'] = @arguments.shift.to_s.downcase

        if @arguments.present?
          # Collect all arguments that look like fingerprint-material
          fingerprint = ''
          while @arguments.first.present? && @arguments.first.match(/^(0x)?[a-f0-9]+$/i)
            fingerprint << @arguments.shift.downcase
          end

          subscription_params['fingerprint'] = fingerprint
          # Use possibly remaining args as flags.
          subscription_params['admin'] = @arguments.shift.to_s.downcase.presence
          subscription_params['delivery_enabled'] = @arguments.shift.to_s.downcase.presence
        end

        subscription, _ = subscriptions_controller.subscribe(@list.email, subscription_params, nil)

        if subscription.persisted?
          t('subscribed', {
              email: subscription.email,
              fingerprint: subscription.fingerprint,
              admin: subscription.admin,
              delivery_enabled: subscription.delivery_enabled
          })
        else
          t('subscribing_failed', {
              email: subscription.email,
              errors: subscription.errors.full_messages.join(".\n")
          })
        end
      end

    end
  end
end
