module Schleuder
  module Errors
    class MessageUnauthenticated < Base
      def initialize(list)
        set_default_locale
      end

      def message
        t('errors.message_unauthenticated')
      end
    end
  end
end
