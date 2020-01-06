module Schleuder
  module KeywordHandlers
    class CustomKeyword < Base
      handles_request_keyword 'custom-keyword', with_method: :custom_keyword

      def custom_keyword
        'Something something'
      end
    end
  end
end
