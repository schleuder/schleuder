module Schleuder
  class SubscriptionsController < BaseController
    def find_all(filter={})
      authorize!(Subscription, :list)
      current_account.scoped(Subscription).where(filter)
    end

    def find(email)
      subscription = Subscription.where(email: email).first
      authorize!(subscription, :read)
      subscription
    end

    def subscribe(list_id, attributes, key_material)
      list = get_list_by_id_or_email(list_id)
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
      subscription = Subscription.where(email: email).first
      authorize!(subscription, :update)
      subscription.update(attributes)
    end

    def delete(email)
      subscription = Subscription.where(email: email).first
      authorize!(subscription, :delete)
      subscription.destroy
    end

    def get_configurable_attributes
      Subscription.configurable_attributes
    end

    def new_subscription
      Subscription.new
    end
  end
end
