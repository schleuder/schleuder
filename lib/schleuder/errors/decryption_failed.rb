module Schleuder
  module Errors
    class DecryptionFailed < Base
      def initialize(list)
        @list = list
      end

      def message
        t('errors.decryption_failed',
          { key: @list.key.to_s,
            sendkey_email: @list.email.gsub(/@/, '-sendkey@') })
      end
    end
  end
end
