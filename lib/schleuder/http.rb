module Schleuder
  class NetworkError < StandardError; end

  class NotFoundError < StandardError; end

  class Http
    attr_reader :request, :response

    def initialize(url, options={})
      @request = Typhoeus::Request.new(url, default_options.merge(options))
    end

    def run
      @response = @request.run
      if @response.success?
        @response.body
      elsif @response.timed_out?
        raise_network_error(response, 'HTTP Request timed out.')
      elsif @response.code == 404
        NotFoundError.new
      elsif @response.code == 0
        # This happens e.g. if no response could be received.
        raise_network_error(@response, 'No HTTP response received.')
      else
        RuntimeError.new(@response.body.to_s.presence || @response.return_message)
      end
    end

    def self.get(url)
      nth_attempt ||= 1
      new(url).run
    rescue NetworkError => error
      nth_attempt += 1
      if nth_attempt < 4
        retry
      else
        return error
      end
    end

    private

    def raise_network_error(response, fallback_msg)
      raise NetworkError.new(
        response.body.to_s.presence || response.return_message || fallback_msg
      )
    end

    def default_options
      {
        followlocation: true,
        proxy: Conf.http_proxy.presence
      }
    end
  end
end
