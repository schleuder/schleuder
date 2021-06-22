module Schleuder
  class SksClient < Http
    SKS_PATH = '/pks/lookup?&exact=on&op=get&options=mr&search=SEARCH_ARG'

    class << self
      def get(input)
        super(url(input))
      end

      private

      def url(input)
        arg = CGI.escape(input.gsub(/\s/, ''))
        Conf.sks_keyserver + SKS_PATH.gsub('SEARCH_ARG', arg)
      end
    end
  end
end
