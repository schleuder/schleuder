module Schleuder
  module Errors
    class KeyNotFound < Base
      def initialize(fingerprint)
        super t('errors.key_not_found', fingerprint: fingerprint)
      end
    end
  end
end

