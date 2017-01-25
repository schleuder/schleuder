module Schleuder
  module Errors
    class KeywordAdminOnly < Base
      def initialize(keyword)
        @keyword = keyword
      end

      def message
        t('errors.keyword_admin_only', keyword: @keyword)
      end
    end
  end
end
