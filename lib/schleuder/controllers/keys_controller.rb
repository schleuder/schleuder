module Schleuder
  class KeysController < BaseController
    def get_keys(list_id)
      list = get_list(list_id)
      authorize(current_account, list, :list_keys)
      list.keys
    end

    def import_key(list_id, key)
      list = get_list(list_id)
      authorize(current_account, list, :add_keys)
      list.import_key(key)
    end

    def check_keys(list_id)
      list = get_list(list_id)
      authorize(current_account, list, :check_keys)
      list.check_keys
    end

    def get_key(list_id, fingerprint)
      list = get_list(list_id)
      key = list.key(fingerprint)
      authorize(current_account, key, :read)
      key
    end

    def delete_key(list_id, fingerprint)
      list = get_list(list_id)
      key = list.key(fingerprint) || halt(404)
      authorize(current_account, key, :delete)
      key.delete!
    end

    private

    def get_list(list_id)
      List.where(id: list_id).first
    end
  end
end
