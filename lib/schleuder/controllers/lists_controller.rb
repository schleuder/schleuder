module Schleuder
  class ListsController < BaseController
    def find_all
      current_account.scoped(List)
    end

    def create(email, fingerprint, adminaddress, adminfingerprint, adminkey)
      authorize!(List, :create)
      ListBuilder.new(
        {email: email, fingerprint: fingerprint}, adminaddress, adminfingerprint, adminkey
      ).run
    end

    def new_list
      List.new
    end

    def find(email)
      list = get_list(email)
      authorize!(list, :read)
      list
    end

    def update(email, attributes)
      list = get_list(email)
      authorize!(list, :update)
      list.update(attributes)
    end

    def delete(email)
      list = get_list(email)
      authorize!(list, :delete)
      list.destroy
    end

    def get_configurable_attributes
      List.configurable_attributes
    end

    def send_list_key_to_subscriptions(email)
      list = get_list(email)
      authorize!(list, :send_list_key)
      list.send_list_key_to_subscriptions
    end
  end
end
