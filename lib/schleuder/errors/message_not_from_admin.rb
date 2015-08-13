module Schleuder
  module Errors
    class MessageNotFromAdmin < Base
      def initialize(list)
        set_default_locale
      end

      def message
        t('errors.message_not_from_admin')
      end
    end
  end
end
