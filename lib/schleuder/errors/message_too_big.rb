module Schleuder
  module Errors
    class MessageTooBig < Base
      def initialize(list)
        @allowed_size = list.max_message_size_kb
      end

      def message
        t('errors.message_too_big', { allowed_size: @allowed_size })
      end
    end
  end
end
