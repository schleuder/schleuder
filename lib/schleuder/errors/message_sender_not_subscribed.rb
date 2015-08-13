module Schleuder
  module Errors
    class MessageSenderNotSubscribed < Base
      def initialize(list)
        @list = list
      end

      def message
        t('errors.message_sender_not_subscribed')
      end
    end
  end
end
