module Schleuder
  module Errors
    class MessageUnsigned < Base
      def initialize(list)
        @list = list
      end

      def message
        t('errors.message_unsigned',
          {
            owner_email: @list.email.gsub(/@/, '-owner@'),
            list_fingerprint: @list.fingerprint
          }
         )
      end
    end
  end
end
