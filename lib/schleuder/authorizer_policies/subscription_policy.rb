module Schleuder
  module AuthorizerPolicies
    class SubscriptionPolicy < BasePolicy
      class Scope < BaseScope
        def resolve
          if account.api_superadmin?
            Subscription.all
          else
            account.admin_list_subscriptions
          end
        end
      end

      # If subscriptions for a given list are checked, call ListPolicy#list_subscriptions
      def list
        true
      end

      def read?
        superadmin? || admin?(object.list) || own?(object)
      end

      def update?
        superadmin? || admin?(object.list) || own?(object)
      end

      # create is not defined: it must be checked via ListPolicy#subscribe (because we need the list-context).

      def delete?
        superadmin? || admin?(object.list) || own?(object)
      end

      private

      def own?(object)
        account.subscriptions.include?(object)
      end
    end
  end
end
