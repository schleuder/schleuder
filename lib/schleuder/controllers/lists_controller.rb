module Schleuder
  class ListsController < BaseController
    def find_all
      current_account.scoped(List)
    end

    def create(listname, fingerprint, adminaddress, adminfingerprint, adminkey)
      authorized?(List, :create)
      ListBuilder.new(
        {email: listname, fingerprint: fingerprint}, adminaddress, adminfingerprint, adminkey
      ).run
    end

    def new_list
      List.new
    end

    def find(identifier)
      list = get_list_by_id_or_email(identifier)
      authorized?(list, :read)
      list
    end

    def update(identifier, attributes)
      list = get_list_by_id_or_email(identifier)
      authorized?(list, :update)
      list.update(attributes)
    end

    def delete(identifier)
      list = get_list_by_id_or_email(identifier)
      authorized?(list, :delete)
      list.destroy
    end

    def get_configurable_attributes
      List.configurable_attributes
    end

    def send_list_key_to_subscriptions(list_id)
      list = get_list_by_id_or_email(list_id)
      authorized?(list, :send_list_key)
      list.send_list_key_to_subscriptions
    end
  end
end
