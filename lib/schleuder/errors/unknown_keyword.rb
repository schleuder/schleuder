module Schleuder
  module Errors
    class UnknownKeyword < Base
      def initialize(keyword)
        super t('errors.unknown_keyword', keyword: keyword)
      end
    end
  end
end

