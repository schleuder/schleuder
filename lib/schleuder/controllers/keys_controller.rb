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
      key = get_key(list_id, fingerprint)
      authorize!(key, :read)
      key
    end

    def delete(list_id, fingerprint)
      key = get_key(list_id, fingerprint)
      authorize!(key, :delete)
      key.delete!
    end

    private

    def get_key(list_email, fingerprint)
      list = get_list(list_email)
      key = list.key(fingerprint)
      raise Errors::KeyNotFound.new(fingerprint) if key.blank?
      key
    end
  end
end
