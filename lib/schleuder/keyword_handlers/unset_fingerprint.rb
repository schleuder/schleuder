module Schleuder
  module KeywordHandlers
    class UnsetFingerprint < Base
      handles_request_keyword 'unset-fingerprint', with_arguments: [Conf::EMAIL_REGEXP]

      def run(mail)
        # TODO: Do we still need this check?
        if @arguments.blank?
          return t('unset_fingerprint_requires_arguments')
        end

        email = @arguments.shift.to_s.downcase

        # Admins degrade themselves to subscribers if they unset they
        # fingerprint. We allow that only with an additional argument.
        if email == mail.signer.email && mail.list.from_admin?(mail) && @arguments.last.to_s.downcase != 'force'
          return t('unset_fingerprint_requires_arguments')
        end

        # TODO: Nicer error message for subscriptions that wrongly tried to unset someone elses fingerprint?
        # I18n key: 'keyword_handlers.subscription_management.unset_fingerprint_only_self'

        subscription = subscriptions_controller.update(mail.list.email, email, {fingerprint: ''})

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
