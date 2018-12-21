module Schleuder
  module AuthorizerPolicies
    class SubscriptionPolicy < BasePolicy
      class Scope < BaseScope
        def resolve
          if account.api_superadmin?
            Subscription.all
          else
            # TODO: use subscriber_permissions for this scoping.
            account.admin_list_subscriptions
          end
        end
      end

      # list?() is not defined: it must be checked via
      # ListPolicy#list_subscriptions (we must use the list-object, because we
      # have no subscription instance in this case.)

      def read?
        superadmin? || admin?(resource.list) || own?(resource) || subscriber_permitted?(resource.list, 'view-subscriptions')
      end

      def update?
        superadmin? || admin?(resource.list) || own?(resource) || subscriber_permitted?(resource.list, 'add-subscriptions')
      end

      # create?() is not defined: it must be checked via
      # ListPolicy#add_subscriptions (we must use the list-object, because we
      # have no subscription instance in this case.)

      def delete?
        superadmin? || admin?(resource.list) || own?(resource) || subscriber_permitted?(resource.list, 'delete-subscriptions')
      end

      private

      def own?(resource)
        account.subscriptions.include?(resource)
      end

    end
  end
end
