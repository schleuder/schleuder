module Schleuder
  class SubscriptionsController < BaseController
    def find_all(filter={})
      authorized?(Subscription, :list)
      current_account.scoped(Subscription).where(filter)
    end

    def find(id)
      subscription = Subscription.where(id: id).first
      authorized?(subscription, :read)
      subscription
    end

    def subscribe(list_id, attributes, key_material)
      list = get_list_by_id_or_email(list_id)
      authorized?(list, :subscribe)
      list.subscribe(
        attributes['email'],
        attributes['fingerprint'],
        attributes['admin'],
        attributes['delivery_enabled'],
        key_material
      )
    end

    def update(id, attributes)
      subscription = Subscription.where(id: id).first
      authorized?(subscription, :update)
      subscription.update(attributes)
    end

    def delete(id)
      subscription = Subscription.where(id: id).first
      authorized?(subscription, :delete)
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
