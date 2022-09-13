module Schleuder
  class KeyFetcher
    def initialize(list)
      @list = list
    end

    def fetch(input, locale_key='key_fetched')
      result = case input
               when /^http/
                 fetch_key_by_url(input)
               when Conf::EMAIL_REGEXP
                 fetch_key_from_keyserver('email', input)
               when Conf::FINGERPRINT_REGEXP
                 fetch_key_from_keyserver('fingerprint', input)
               else
                 return I18n.t('key_fetcher.invalid_input')
               end
      if result.is_a?(NotFoundError)
        result = NotFoundError.new(I18n.t('key_fetcher.not_found', input: input))
      else
      interpret_fetch_result(result, locale_key)
    end

    def fetch_key_by_url(url)
      Schleuder::Http.get(url)
    end

    def fetch_key_from_keyserver(type, input)
      if Conf.vks_keyserver.present?
        result = Schleuder::VksClient.get(type, input)
      end
      if (result.blank? || ! result.is_a?(String)) && Conf.sks_keyserver.present?
        result = Schleuder::SksClient.get(input)
      end

      if result.blank?
        RuntimeError.new('No keyserver configured, cannot query anything')
      else
        result
      end
    end

    private

    def interpret_fetch_result(result, locale_key)
      case result
      when ''
        RuntimeError.new(I18n.t('key_fetcher.general_error', error: 'Empty response from server'))
      when String
        import(result, locale_key)
      when NotFoundError
        result
      when StandardError
        RuntimeError.new(I18n.t('key_fetcher.general_error', error: result))
      else
        raise_unexpected_error(result)
      end
    end

    def import(input, locale_key)
      result = @list.gpg.import_from_string(locale_key, input)
      case result
      when StandardError
        RuntimeError.new(I18n.t('key_fetcher.import_error', error: result))
      when String
        result
      else
        raise_unexpected_error(result)
      end
    end

    def raise_unexpected_error(thing)
      raise "Unexpected output => #{thing.inspect}"
    end
  end
end
