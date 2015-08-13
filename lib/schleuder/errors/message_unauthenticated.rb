module Schleuder
  module Errors
    class MessageUnauthenticated < Base
      def initialize(list)
        @list = list
      end

      def message
        t('errors.message_unauthenticated')
      end
    end
  end
end
