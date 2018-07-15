module Schleuder
  module RequestPlugins
    def self.subscribe(arguments, list, mail)
      if arguments.blank?
        return I18n.t(
          "plugins.subscription_management.subscribe_requires_arguments"
        )
      end

      email = arguments.shift

      if arguments.present?
        # Collect all arguments that look like fingerprint-material
        fingerprint = ''
        while arguments.first.present? && arguments.first.match(/^(0x)?[a-f0-9]+$/i)
          fingerprint << arguments.shift
        end
        # Use possibly remaining args as flags.
        adminflag = arguments.shift
        deliveryflag = arguments.shift
      end

      sub, _ = list.subscribe(email, fingerprint, adminflag, deliveryflag)

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

      # Refuse to unsubscribe the last admin.
      if list.admins.size == 1 && list.admins.first.email == email
        return I18n.t(
          "plugins.subscription_management.cannot_unsubscribe_last_admin", email: email
        )
      end

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

      out = [ I18n.t("plugins.subscription_management.list_of_subscriptions") ]

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

      out.join("\n")
    end

    def self.set_fingerprint(arguments, list, mail)
      if arguments.blank?
        return I18n.t(
          "plugins.subscription_management.set_fingerprint_requires_arguments"
        )
      end

      if arguments.first.match(/@/)
        if arguments.first == mail.signer.email || list.from_admin?(mail)
          email = arguments.shift
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

      fingerprint = arguments.join
      unless GPGME::Key.valid_fingerprint?(fingerprint)
        return I18n.t(
          "plugins.subscription_management.set_fingerprint_requires_valid_fingerprint",
          fingerprint: fingerprint
        )
      end

      sub.fingerprint = fingerprint
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
          fingerprint: sub.fingerprint,
          errors: sub.errors.to_a.join("\n")
        )
      end
    end
  end
end

