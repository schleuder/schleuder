module Schleuder
  class ListsController < BaseController
    def lists
      current_account.scoped(List)
    end

    def create(listname, fingerprint, adminaddress, adminfingerprint, adminkey)
      authorize(current_account, List, :create)
      ListBuilder.new(
        {email: listname, fingerprint: fingerprint}, adminaddress, adminfingerprint, adminkey
      ).run
    end

    def new
      List.new
    end

    def list(identifier)
      list = get_list_by(identifier)
      authorize(current_account, list, :read)
      list
    end

    def update(identifier, attributes)
      list = get_list_by(identifier)
      authorize(current_account, list, :update)
      list.update(attributes)
    end

    def delete(identifier)
      list = get_list_by(identifier)
      authorize(current_account, list, :delete)
      list.destroy
    end

    def get_configurable_attributes
      List.configurable_attributes
    end

    def send_list_key_to_subscriptions(list_id)
      list = get_list_by(list_id)
      authorize(current_account, list, :send_list_key)
      list.send_list_key_to_subscriptions
    end

    private

    def get_list_by(identifier)
      query_args = to_query_args(identifier)
      List.where(query_args).first
    end

    def to_query_args(identifier)
      if is_an_integer?(identifier)
        {id: identifier.to_i}
      else
        {email: identifier.to_s}
      end
    end

    def is_an_integer?(input)
      input.to_s.match(/^[0-9]+$/).present?
    end
  end
end
