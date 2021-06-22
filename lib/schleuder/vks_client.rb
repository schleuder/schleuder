module Schleuder
  class VksClient < Http
    VKS_PATH = '/vks/v1'

    class << self
      def get(type, input)
        if type.to_s == 'fingerprint'
          input = normalize_fingerprint(input)
        end
        super(url(type, input))
      end

      private

      def normalize_fingerprint(input)
        input.gsub(/^0x/, '').gsub(/\s/, '').upcase
      end

      def url(type, input)
        "#{Conf.vks_keyserver}/#{VKS_PATH}/by-#{type}/#{CGI.escape(input)}"
      end
    end
  end
end
