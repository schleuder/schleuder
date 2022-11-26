module Schleuder
  class KeyFetcher
    def initialize(list)
      @list = list
    end

    def fetch_by_url(input)
      interpret_fetch_result(fetch_key_by_url(input))
    end

    def fetch_by_email_address(input)
      result = fetch_key_from_wkd(input)
      if result.is_a?(StandardError)
        result = fetch_key_from_vks('email', input)
      end
      interpret_fetch_result(result)
    end

    def fetch_by_fingerprint(input)
      if Conf.vks_keyserver.present?
        Schleuder.logger.info("Fetching key for #{input.inspect} from VKS-keyserver")
        result = Schleuder::VksClient.get('fingerprint', input)
      if result.is_a?(StandardError)
        result = fetch_key_from_sks(input)
        if Conf.sks_keyserver.present?
          Schleuder.logger.info("Fetching key for #{input.inspect} from SKS-keyserver")
          Schleuder::SksClient.get(input)
        else
          RuntimeError.new('No sks_keyserver configured, cannot fetch data')
        end
      end
      interpret_fetch_result(result)
    end

    private

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

    def interpret_fetch_result(result)
      case result
      when ''
        RuntimeError.new(I18n.t('key_fetcher.general_error', error: 'Empty response from server'))
      when String
        result
      when NotFoundError
        NotFoundError.new(I18n.t('key_fetcher.not_found', input: input))
      when StandardError
        # TODO: This currently includes "no sks_keyserver configured…" as error
        # message if none was configured (as will be the default), overriding a
        # possible error from fetching from the VKS server
        RuntimeError.new(I18n.t('key_fetcher.general_error', error: result))
      else
        raise "Unexpected output => #{thing.inspect}"
      end
    end

  end
end
