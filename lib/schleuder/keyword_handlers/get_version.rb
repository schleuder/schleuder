module Schleuder
  module KeywordHandlers
    class GetVersion < Base
      handles_request_keyword 'get-version'

      WANTED_ARGUMENTS = []

      def run(mail)
        Schleuder::VERSION
      end
    end
  end
end
