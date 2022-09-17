module Schleuder
  class KeyFetcher
    def initialize(list)
      @list = list
    end

    def fetch(input, locale_key='key_fetched')
      case input
      when /^http/
        result = fetch_key_by_url(input)
      when Conf::EMAIL_REGEXP
        result = fetch_key_from_wkd(input)
        if result.is_a?(StandardError)
          result = fetch_key_from_vks('email', input)
        end
      when Conf::FINGERPRINT_REGEXP
        result = fetch_key_from_vks('fingerprint', input)
        if result.is_a?(StandardError)
          result = fetch_key_from_sks(input)
        end
      else
        return I18n.t('key_fetcher.invalid_input')
      end

      if result.is_a?(NotFoundError)
        result = NotFoundError.new(I18n.t('key_fetcher.not_found', input: input))
      else
      interpret_fetch_result(result, locale_key)
    end

    def fetch_key_by_url(url)
      Schleuder.logger.info("Fetching #{url.inspect}")
      Schleuder::Http.get(url)
    end

    def fetch_key_from_wkd(input)
      Schleuder.logger.info("Fetching key for #{input.inspect} from WKD")
      Schleuder::WkdClient.get(input)
    end

    def fetch_key_from_vks(type, input)
      if Conf.vks_keyserver.present?
        Schleuder.logger.info("Fetching key for #{input.inspect} from VKS-keyserver")
        Schleuder::VksClient.get(type, input)
      else
        RuntimeError.new('No vks_keyserver configured, cannot fetch data')
      end
    end

    def fetch_key_from_sks(input)
      if Conf.sks_keyserver.present?
        Schleuder.logger.info("Fetching key for #{input.inspect} from SKS-keyserver")
        Schleuder::SksClient.get(input)
      else
        RuntimeError.new('No sks_keyserver configured, cannot fetch data')
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

    # TODO: Filter on import to ensure only importing keys with the wanted
    # features. After all we're fetching content from the internet, which could
    # be anything.
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
