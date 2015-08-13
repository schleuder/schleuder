module Schleuder
  module Errors
    class MessageNotFromAdmin < Base
      def initialize(list)
        @list = list
      end

      def message
        t('errors.message_not_from_admin')
      end
    end
  end
end
