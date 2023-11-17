module Schleuder
  class NotFoundError < StandardError; end

  class Http
    class << self
      def get(url)
        response = httpx.get(url)
        status_code = if response.error
                        response.error.status
                      else
                        response.status
                      end
        case status_code
        when 200..299
          response.body.read
        when 404
          NotFoundError.new
        else
          RuntimeError.new(response)
        end
      end

      private

      def httpx
        httpx = HTTPX
          .plugin(:follow_redirects)
          .plugin(:retries, retry_after: 1).max_retries(3)
        if Conf.http_proxy.present?
          httpx = httpx.plugin(:proxy).with_proxy(uri: Conf.http_proxy)
        end
        httpx
      end
    end
  end
end
