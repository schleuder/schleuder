module Schleuder
  module Errors
    class MessageUnencrypted < Base
      def initialize
        set_default_locale
        super t('errors.message_unencrypted')
      end
    end
  end
end
