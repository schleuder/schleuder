module Schleuder
  module KeywordHandlers
    class SubscriptionManagement < Base
      #handles_request_keyword 'subscribe', with_method: :subscribe, wanted_arguments: [Conf::EMAIL_REGEXP, /(true|false)?/, /(true|false)?/, /(#{Conf::FINGERPRINT_REGEXP_EMBED})?/]

      handles_request_keyword 'subscribe',
                              with_method: :subscribe,
                              wanted_arguments: lambda { |arguments|
                                # TODO: save arguments here, otherwise we'd need to collect the parts of the fingerprint again later.
                                return :more if arguments.blank?

                                email = arguments.shift.downcase
                                if ! email.match(Conf::EMAIL_REGEXP)
                                  raise "Error: Keyword 'subscribe' needs a valid email address as first argument."
                                end

                                return :more if arguments.blank?

                                # Collect all arguments that look like fingerprint-material
                                fingerprint = ''
                                while arguments.first.present? && arguments.first.match(/^(0x)?[a-f0-9]+$/i)
                                  fingerprint << arguments.shift.downcase
                                end

                                if ! fingerprint.match(Conf::FINGERPRINT_REGEXP)
                                  return :invalid
                                end

                                return :more if arguments.blank?

                                adminflag = arguments.shift.downcase.presence
                                if ! %[true false].include?(adminflag)
                                  return :invalid
                                end

                                return :more if arguments.blank?

                                delivery_enabled = arguments.shift.downcase.presence
                                if ! %[true false].include?(delivery_enabled)
                                  return :invalid
                                end

                                return :end
                              }
                                

      handles_request_keyword 'unsubscribe', with_method: :unsubscribe, wanted_arguments: [/(#{Conf::EMAIL_REGEXP_EMBED})?/]

      handles_request_keyword 'list-subscriptions', with_method: :list_subscriptions, wanted_arguments: [/.*/]

      handles_request_keyword 'set-fingerprint', with_method: :set_fingerprint, wanted_arguments: [/(#{Conf::EMAIL_REGEXP_EMBED}|#{Conf::FINGERPRINT_REGEXP_EMBED})/, /(#{Conf::FINGERPRINT_REGEXP_EMBED})?/]

      handles_request_keyword 'unset-fingerprint', with_method: :unset_fingerprint, wanted_arguments: [Conf::EMAIL_REGEXP]

      def subscribe
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

      def unsubscribe
        # If no address was given we unsubscribe the sender.
        email = @arguments.first.to_s.downcase.presence || @mail.signer.email

        subscription = subscriptions_controller.delete(@list.email, email)

        if subscription.destroyed?
          t('.unsubscribed', email: subscription.email)
        else
          t('unsubscribing_failed', email: subscription.email, error: subscription.errors.to_a)
        end
      end

      def list_subscriptions
        subscriptions = subscriptions_controller.find_all(@list.email).to_a

        if @arguments.present?
          regexp = Regexp.new(@arguments.join('|'))
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

      def set_fingerprint
        if @arguments.blank?
          return t('set_fingerprint_requires_arguments')
        end

        if @arguments.first.match(/@/)
          email = @arguments.shift.downcase
        else
          email = @mail.signer.email
        end

        fingerprint = @arguments.join
        if !GPGME::Key.valid_fingerprint?(fingerprint)
          return t('set_fingerprint_requires_valid_fingerprint', fingerprint: fingerprint)
        end

        subscription = subscriptions_controller.update(@list.email, email, {fingerprint: fingerprint})

        # TODO: Nicer error message for subscriptions that wrongly tried to set someone elses fingerprint?
        # I18n key: 'keyword_handlers.subscription_management.set_fingerprint_only_self'

        if subscription.valid?
          t('fingerprint_set', {
              email: subscription.email,
              fingerprint: subscription.fingerprint
          })
        else
          # TODO: Use 'keyword_handlers.subscription_management.set_fingerprint_requires_valid_fingerprint' if fingerprint is invalid.
          t('setting_fingerprint_failed', {
              email: subscription.email,
              fingerprint: subscription.fingerprint,
              errors: subscription.errors.to_a.join("\n")
          })
        end
      end

      def unset_fingerprint
        if @arguments.blank?
          return t('unset_fingerprint_requires_arguments')
        end

        email = @arguments.shift.to_s.downcase

        # Admins degrade themselves to subscribers if they unset they
        # fingerprint. We allow that only with an additional argument.
        if email == @mail.signer.email && @list.from_admin?(@mail) && @arguments.last.to_s.downcase != 'force'
          return t('unset_fingerprint_requires_arguments')
        end

        # TODO: Nicer error message for subscriptions that wrongly tried to unset someone elses fingerprint?
        # I18n key: 'keyword_handlers.subscription_management.unset_fingerprint_only_self'

        subscription = subscriptions_controller.update(@list.email, email, {fingerprint: ''})

        if subscription.valid?
          t('fingerprint_unset', {email: subscription.email})
        else
          t('unsetting_fingerprint_failed', {
              email: subscription.email,
              errors: subscription.errors.to_a.join("\n")
          })
        end
      end
    end
  end
end
