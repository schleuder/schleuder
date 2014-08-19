module Schleuder
  module Plugins
    def self.subscribe(arguments, list, mail)
      sub = list.subscriptions.new(
        email: arguments.first,
        fingerprint: arguments.last
      )

      if sub
        I18n.t(
          "plugins.subscription_management.subscribed",
          email: email,
          fingerprint: sub.fingerprint
        )
      else
        I18n.t(
          "plugins.subscription_management.subscribing_failed",
          email: sub.email,
          error: sub.errors.to_a
        )
      end
    end

    def self.add_member(*args)
      self.subscribe(*args)
    end

    def self.unsubscribe(arguments, list, mail)
      email = if list.admin?(mail.signer.email)
                arguments.first
              else
                # TODO: send error message if signer tried to unsubscribe
                # another address than hir own.
                mail.signer.email
              end

      sub = list.subscriptions.where(email: email)

      if sub.blank?
        return I18n.t(
          "plugins.subscription_management.is_not_subscribed", email: email
        )
      end

      if res = sub.delete
        I18n.t(
          "plugins.subscription_management.unsubscribed", email: email
        )
      else
        I18n.t(
          "plugins.subscription_management.unsubscribing_failed",
          email: email,
          error: res.errors.to_a
        )
      end
    end

    def self.delete_member(*args)
      self.unsubscribe(*args)
    end

    def self.list_subscriptions(arguments, list, mail)
      out = [
        "#{I18n.t("plugins.subscription_management.list_of_subscriptions")}:"
      ]

      subs = if arguments.blank?
                list.subscriptions.all.to_a
             else
               arguments.map do |argument|
                 list.subscriptions.where("email like ?", "%#{argument}%").to_a
               end.flatten
             end

      out << subs.map do |subscription|
        # Fingerprints are at most 40 characters long, and lines shouldn't
        # exceed 80 characters if possible.
        "#{subscription.email.rjust(39)} #{subscription.fingerprint}"
      end
    end

    def self.list_members(*args)
      self.list_subscriptions(*args)
    end

    def self.list_subscribers(*args)
      self.list_subscriptions(*args)
    end

    def self.set_fingerprint(arguments, list, mail)
      email = if list.admin?(mail.signer.email)
                arguments.first
              else
                # TODO: send error message if signer tried to set another
                # fingerprint than hir own.
                mail.signer.email
              end

      sub = list.subscriptions.where(email: mail.signer.email)

      if sub.blank?
        return I18n.t(
          "plugins.subscription_management.is_not_subscribed", email: email
        )
      end

      sub.fingerprint = arguments.last

      if sub.save
        I18n.t(
          "plugins.subscription_management.fingerprint_set",
          email: email,
          fingerprint: sub.fingerprint
        )
      else
        I18n.t(
          "plugins.subscription_management.setting_fingerprint_failed",
          email: email,
          fingerprint: arguments.last,
          error: sub.errors.to_a.join("\n")
        )
      end
    end
  end
end

