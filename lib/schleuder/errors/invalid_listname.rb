module Schleuder
  module Errors
    class InvalidListname < Base
      def initialize(listname)
        @listname = listname
      end

      def message
        t('errors.invalid_listname', email: @listname)
      end
    end
  end
end
