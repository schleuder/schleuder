module Schleuder
  class SubscriptionsController < BaseController
    def find_all(list_email, filter={})
      list = get_list(list_email)
      authorize!(list, :list_subscriptions)
      list.subscriptions.where(filter)
    end

    def find(list_email, email)
      subscription = get_subscription(list_email, email)
      authorize!(subscription, :read)
      subscription
    end

    def subscribe(list_email, attributes, key_material)
      list = get_list(list_email)
      authorize!(list, :subscribe)
      list.subscribe(
        attributes['email'],
        attributes['fingerprint'],
        attributes['admin'],
        attributes['delivery_enabled'],
        key_material
      )
    end

    def update(list_email, email, attributes)
      subscription = get_subscription(list_email, email)
      authorize!(subscription, :update)
      subscription.update(attributes)
      subscription
    end

    def delete(list_email, email)
      subscription = get_subscription(list_email, email)
      authorize!(subscription, :delete)
      ensure_deletable!(subscription)
      subscription.destroy
    end

    def get_configurable_attributes
      Subscription.configurable_attributes
    end

    def new_subscription
      Subscription.new
    end

    private

    def get_subscription(list_email, email)
      subscription = Subscription.find_by(email: email.to_s)
      raise Errors::SubscriptionNotFound.new(email) if subscription.blank?
      subscription
    end
    
    # Refuse to unsubscribe the last admin.
    def ensure_deletable!(subscription)
      if subscription.admin? && subscription.list.admins.size == 1
        raise Errors::LastAdminNotDeletable.new(subscription)
      end
    end
  end
end
