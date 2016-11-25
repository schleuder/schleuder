module Schleuder
  module Errors
    class MessageEmpty < Base
      def initialize(list)
        set_default_locale
        @request_address = list.request_address
      end

      def message
        t('errors.message_empty', { request_address: @request_address })
      end
    end
  end
end
