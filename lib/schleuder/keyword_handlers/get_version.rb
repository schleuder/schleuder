module Schleuder
  module KeywordHandlers
    class GetVersion < Base
      handles_request_keyword 'get-version', with_arguments:  []

      def run(mail)
        Schleuder::VERSION
      end
    end
  end
end
