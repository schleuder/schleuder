module Schleuder
  module Errors
    class MessageUnencrypted < Base
      def initialize(list)
        @list = list
      end

      def message
        t('errors.message_unencrypted')
      end
    end
  end
end
