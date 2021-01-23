module Schleuder
  module KeywordHandlers
    class SetFingerprint < Base
      handles_request_keyword 'set-fingerprint', with_arguments: []
      FPR_REGEXP = /^(0x)?[a-f0-9]+$/i
      SPACED_FPR = /^(0x)?[a-f0-9]{4} ?[a-f0-9]{4} ?[a-f0-9]{4} ?[a-f0-9]{4} ?[a-f0-9]{4} {0,2}[a-f0-9]{4} ?[a-f0-9]{4} ?[a-f0-9]{4} ?[a-f0-9]{4} ?[a-f0-9]{4} ?$/i

      # This method returns the collected arguments as second return value so
      # the actual method doesn't have to check for a space-delimited
      # fingerprint again.
      def validate_arguments(arguments)
        return :more if arguments.blank?

        # TODO: manipulate `arguments` instead of returning a new variable
        args_to_save = []

        first = arguments.shift.downcase
        if first.match(Conf::EMAIL_REGEXP)
          args_to_save << first
          fingerprint = ''
          # TODO: refactor with next block
          while arguments.first.present? && arguments.first.match(FPR_REGEXP)
            fingerprint << arguments.shift.downcase
          end
          args_to_save << fingerprint
        elsif first.match(FPR_REGEXP)
          # Collect all arguments that look like fingerprint-material
          fingerprint = first
          while arguments.first.present? && arguments.first.match(FPR_REGEXP)
            fingerprint << arguments.shift.downcase
          end
          args_to_save << fingerprint
        else
          return :invalid
        end

        if arguments.present?
          return :invalid
        end

        if args_to_save.last.match?(Conf::FINGERPRINT_REGEXP)
          return :end, args_to_save
        else
          return :more, args_to_save
        end
      end

      def run
        if @invalid_arguments.any?
          # TODO: collecting the input like this is ugly, let's improve that!
          return t('set_fingerprint_requires_valid_fingerprint', fingerprint: (@arguments + @invalid_arguments).map(&:presence).compact.join(' '))
        end

        if @arguments.blank?
          return t('set_fingerprint_requires_arguments')
        end

        if @arguments.first.match(/@/)
          email = @arguments.first.downcase
          fingerprint = @arguments.second
        else
          email = @mail.signer.email
          fingerprint = @arguments.first
        end

        if !GPGME::Key.valid_fingerprint?(fingerprint)
          return t('set_fingerprint_requires_valid_fingerprint', fingerprint: (@arguments + @invalid_arguments).map(&:presence).compact.join(' '))
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
    end
  end
end
