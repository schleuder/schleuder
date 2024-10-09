module Schleuder
  class KeysController < BaseController
    def find_all(list_email, identifier='')
      list = get_list(list_email)
      authorize!(list, :list_keys)
      # In this case it shall be allowed to match keys by arbitrary
      # sub-strings, therefore we use `list.gpg` directly to not have the input
      # filtered.
      list.gpg.keys(identifier)
    end

    def import(list_email, key)
      list = get_list(list_email)
      authorize!(list, :add_keys)
      import_result = list.import_key(key)
      messages = []
      errors = []

      import_result.imports.each do |import_status|
        if import_status.action == "error"
          errors << t("error", fingerprint: import_status.fingerprint)
        else
          key = list.gpg.find_distinct_key(import_status.fingerprint)
          # TODO: handle error case. Shouldn't happen in theory, but who knows.
          if key
            messages << t("key_import_status.#{import_status.action}", key_summary: key.summary)
          end
        end
      end

      if messages.empty? && errors.empty?
        errors << t("no_imports")
      end

      [messages, errors]
    end

    def fetch(list_email, identifier)
      list = get_list(list_email)
      authorize!(list, :add_keys)
      list.fetch_keys(identifier)
    end

    def check(list_email)
      list = get_list(list_email)
      authorize!(list, :check_keys)
      list.check_keys
    end

    def find(list_email, fingerprint)
      key = get_key(list_email, fingerprint)
      authorize!(key, :read)
      key
    end

    def delete(list_email, fingerprint)
      key = get_key(list_email, fingerprint)
      authorize!(key, :delete)
      key.delete!
      key
    end

    private

    def get_key(list_email, fingerprint)
      ensure_this_is_a_fingerprint(fingerprint)
      list = get_list(list_email)
      key = list.key(fingerprint)
      raise Errors::KeyNotFound.new(fingerprint) if key.blank?
      key
    end

    def ensure_this_is_a_fingerprint(fingerprint)
      if !GPGME::Key.valid_fingerprint?(fingerprint)
        raise Errors::KeyNotFound.new(fingerprint)
      end
    end
  end
end
