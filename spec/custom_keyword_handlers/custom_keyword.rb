module Schleuder
  module KeywordHandlers
    class CustomKeyword < Base
      handles_request_keyword 'custom-keyword', with_arguments: []

      def run
        'Something something'
      end
    end
  end
end
