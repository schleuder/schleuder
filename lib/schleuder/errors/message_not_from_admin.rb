module Schleuder
  module Errors
    class MessageNotFromAdmin < Base
      def initialize
        set_default_locale
        super t('errors.message_not_from_admin')
      end
    end
  end
end
