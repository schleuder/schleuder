module Schleuder
  class KeysController < BaseController
    def find_all(list_id)
      list = get_list(list_id)
      authorize!(list, :list_keys)
      list.keys
    end

    def import(list_id, key)
      list = get_list(list_id)
      authorize!(list, :add_keys)
      list.import_key(key)
    end

    def check(list_id)
      list = get_list(list_id)
      authorize!(list, :check_keys)
      list.check_keys
    end

    def find(list_id, fingerprint)
      list = get_list(list_id)
      key = list.key(fingerprint)
      authorize!(key, :read)
      key
    end

    def delete(list_id, fingerprint)
      list = get_list(list_id)
      key = list.key(fingerprint) || halt(404)
      authorize!(key, :delete)
      key.delete!
    end
  end
end
