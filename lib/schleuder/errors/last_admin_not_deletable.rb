module Schleuder
  module Errors
    class LastAdminNotDeletable < Base
      def initialize(subscription)
        super t('errors.cannot_unsubscribe_last_admin', email: subscription.email)
      end
    end
  end
end

