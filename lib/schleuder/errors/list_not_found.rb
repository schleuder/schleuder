module Schleuder
  module Errors
    class ListNotFound < Base
      def initialize(recipient)
        @recipient = recipient
      end

      def message
        t('errors.list_not_found', email: recipient)
      end
    end
  end
end

