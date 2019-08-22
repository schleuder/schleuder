module Schleuder
  module AuthorizerPolicies
    class ListPolicy < BasePolicy
      class Scope < BaseScope
        def resolve
          if account.api_superadmin?
            List.all
          else
            account.lists
          end
        end
      end

      # list?() is not defined because anyone may list lists — but you must
      # call ListPolicy::Scope.resolve to get the correct list of lists.

      def read?
        superadmin? || admin?(resource) || subscriber_permitted?(resource, 'view-list-config')
      end

      def update?
        superadmin? || admin?(resource)
      end

      def create?
        superadmin?
      end

      def delete?
        superadmin?
      end

      def read_subscriptions?
        list_subscriptions?
      end

      def list_subscriptions?
        superadmin? || admin?(resource) || subscriber_permitted?(resource, 'view-subscriptions')
      end

      def add_subscriptions?
        subscribe?
      end
      
      def subscribe?
        superadmin? || admin?(resource) || subscriber_permitted?(resource, 'add-subscriptions')
      end

      def read_keys?
        list_keys?
      end

      def list_keys?
        superadmin? || admin?(resource) || subscriber_permitted?(resource, 'view-keys')
      end

      def add_keys?
        superadmin? || admin?(resource) || subscriber_permitted?(resource, 'add-keys')
      end

      def check_keys?
        superadmin? || admin?(resource)
      end

      def send_list_key?
        superadmin? || admin?(resource)
      end

      def resend_unencrypted?
        superadmin? || admin?(resource) || (subscriber_permitted?(resource, 'resend') && subscriber_permitted?(resource, 'resend-unencrypted'))
      end

      def resend?
        superadmin? || admin?(resource) || subscriber_permitted?(resource, 'resend')
      end
    end
  end
end
