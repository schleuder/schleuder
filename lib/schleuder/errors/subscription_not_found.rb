module Schleuder
  module Errors
    class SubscriptionNotFound < Base
      def initialize(email)
        super t("errors.subscription_not_found", email: email)
      end
    end
  end
end

