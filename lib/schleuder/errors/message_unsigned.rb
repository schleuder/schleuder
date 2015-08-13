module Schleuder
  module Errors
    class MessageUnsigned < Base
      def initialize(list)
        set_default_locale
      end

      def message
        t('errors.message_unsigned')
      end
    end
  end
end
