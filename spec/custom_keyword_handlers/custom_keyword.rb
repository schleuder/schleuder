module Schleuder
  module KeywordHandlers
    class CustomKeyword < Base
      handles_request_keyword 'custom-keyword'

      WANTED_ARGUMENTS = []

      def run(mail)
        'Something something'
      end
    end
  end
end
