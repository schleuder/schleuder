module Schleuder
  module Errors
    class ListExists < Base
      def initialize(listname)
        @listname = listname
      end

      def message
        t('errors.list_exists', email: @listname)
      end
    end
  end
end
