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


      def list?
        true
      end

      def read?
        superadmin? || subscribed?(object)
      end

      def update?
        superadmin? || admin?(object)
      end

      def create?
        superadmin?
      end

      def delete?
        superadmin?
      end

      def list_subscriptions?
        superadmin? || admin?(object)
      end

      def subscribe?
        superadmin? || admin?(object)
      end
      
      def list_keys?
        superadmin? || subscribed?(object)
      end

      def add_keys?
        superadmin? || subscribed?(object)
      end

      def check_keys?
        superadmin? || admin?(object)
      end

      def send_list_key?
        superadmin? || admin?(object)
      end


      private


      # This includes list-admins.
      def subscribed?(list)
        account.subscribed_to_list?(list)
      end
    end
  end
end
