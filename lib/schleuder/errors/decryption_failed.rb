module Schleuder
  module Errors
    class DecryptionFailed < Base
      def initialize(list)
        set_default_locale
        @list = list
      end

      def message
        t('errors.decryption_failed',
          { key: @list.key.to_s,
            email: @list.sendkey_address })
      end
    end
  end
end
