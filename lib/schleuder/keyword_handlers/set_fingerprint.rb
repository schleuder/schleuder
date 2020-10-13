module Schleuder
  module KeywordHandlers
    class SetFingerprint < Base
      handles_request_keyword 'set-fingerprint'

      WANTED_ARGUMENTS = [/(#{Conf::EMAIL_REGEXP_EMBED}|#{Conf::FINGERPRINT_REGEXP_EMBED})/, /(#{Conf::FINGERPRINT_REGEXP_EMBED})?/]

      def run(mail)
        if @arguments.blank?
          return t('set_fingerprint_requires_arguments')
        end

        if @arguments.first.match(/@/)
          email = @arguments.shift.downcase
        else
          email = mail.signer.email
        end

        fingerprint = @arguments.join
        if !GPGME::Key.valid_fingerprint?(fingerprint)
          return t('set_fingerprint_requires_valid_fingerprint', fingerprint: fingerprint)
        end

        subscription = subscriptions_controller.update(mail.list.email, email, {fingerprint: fingerprint})

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
    end
  end
end
