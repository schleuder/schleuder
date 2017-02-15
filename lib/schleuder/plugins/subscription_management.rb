module Schleuder
  module RequestPlugins
    def self.subscribe(arguments, list, mail)
      email = arguments.shift
      fingerprint = arguments.shift
      if fingerprint.present?
        fingerprint.sub!(/^0x/, '')
      end
      adminflag = arguments.shift
      deliveryflag = arguments.shift

      sub = list.subscribe(email, fingerprint, adminflag, deliveryflag)

      if sub.persisted?
        I18n.t(
          "plugins.subscription_management.subscribed",
          email: sub.email,
          fingerprint: sub.fingerprint,
          admin: sub.admin,
          delivery_enabled: sub.delivery_enabled
        )
      else
        I18n.t(
          "plugins.subscription_management.subscribing_failed",
          email: sub.email,
          errors: sub.errors.full_messages.join(".\n")
        )
      end
    end

    def self.unsubscribe(arguments, list, mail)
      # If no address was given we unsubscribe the sender.
      email = arguments.first.presence || mail.signer.email

      # TODO: May signers have multiple UIDs? We don't match those currently.
      if ! list.from_admin?(mail) && email != mail.signer.email
        # Only admins may unsubscribe others.
        return I18n.t(
          "plugins.subscription_management.forbidden", email: email
        )
      end

      sub = list.subscriptions.where(email: email).first

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

    def self.list_subscriptions(arguments, list, mail)
      subs = if arguments.blank?
                list.subscriptions.all.to_a
             else
               arguments.map do |argument|
                 list.subscriptions.where("email like ?", "%#{argument}%").to_a
               end.flatten
             end

      if subs.blank?
        return nil
      end

      out = [
        "#{I18n.t("plugins.subscription_management.list_of_subscriptions")}:"
      ]

      out << subs.map do |subscription|
        # Fingerprints are at most 40 characters long, and lines shouldn't
        # exceed 80 characters if possible.
        s = subscription.email
        if subscription.fingerprint.present?
          s << "\t0x#{subscription.fingerprint}"
        end
        if ! subscription.delivery_enabled?
          s << "\tDelivery disabled!"
        end
        s
      end
    end

    def self.set_fingerprint(arguments, list, mail)
      if arguments.first.match(/@/)
        if arguments.first == mail.signer.email || list.from_admin?(mail)
          email = arguments.first
        else
          return I18n.t(
            "plugins.subscription_management.set_fingerprint_only_self"
          )
        end
      else
        email = mail.signer.email
      end

      sub = list.subscriptions.where(email: email).first

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
          errors: sub.errors.to_a.join("\n")
        )
      end
    end
  end
end

