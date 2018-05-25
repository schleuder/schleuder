module Schleuder
  module Errors
    class MessageUnsigned < Base
      def initialize
        set_default_locale
        super t('errors.message_unsigned')
      end
    end
  end
end
