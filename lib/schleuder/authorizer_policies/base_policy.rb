module Schleuder
  module AuthorizerPolicies
    class BasePolicy
      attr_reader :account, :resource

      class BaseScope
        attr_reader :account

        def initialize(account)
          @account = account
        end
      end

      def initialize(account, resource)
        @account = account
        @resource = resource
      end

      private

      def admin?(list)
        account.admin_of_list?(list)
      end

      def superadmin?
        account.api_superadmin?
      end

      # This includes list-admins.
      def subscribed?(list)
        account.subscribed_to_list?(list)
      end

      def subscriber_permitted?(list, action)
        subscribed?(list) && list.subscriber_permitted?(action)
      end
    end
  end
end
