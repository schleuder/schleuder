module Schleuder
  module Errors
    class NotPgpMime < Base
      def message
        t('errors.not_pgp_mime')
      end
    end
  end
end
