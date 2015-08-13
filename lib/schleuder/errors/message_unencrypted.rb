module Schleuder
  module Errors
    class MessageUnencrypted < Base
      def initialize(list)
        set_default_locale
      end

      def message
        t('errors.message_unencrypted')
      end
    end
  end
end
