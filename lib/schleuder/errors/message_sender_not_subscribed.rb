module Schleuder
  module Errors
    class MessageSenderNotSubscribed < Base
      def initialize
        set_default_locale
        super t('errors.message_sender_not_subscribed')
      end
    end
  end
end
