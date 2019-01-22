module Schleuder
  class SubscriptionsController < BaseController
    def find_all(filter={})
      authorize!(Subscription, :list)
      current_account.scoped(Subscription).where(filter)
    end

    def find(email)
      subscription = get_subscription(email)
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

    def update(email, attributes)
      subscription = get_subscription(email)
      authorize!(subscription, :update)
      subscription.update(attributes)
    end

    def delete(email)
      subscription = get_subscription(email)
      authorize!(subscription, :delete)
      subscription.destroy
    end

    def get_configurable_attributes
      Subscription.configurable_attributes
    end

    def new_subscription
      Subscription.new
    end

    private

    def get_subscription(email)
      subscription = Subscription.find_by(email: email.to_s)
      raise Errors::SubscriptionNotFound.new(email) if subscription.blank?
      subscription
    end
  end
end
