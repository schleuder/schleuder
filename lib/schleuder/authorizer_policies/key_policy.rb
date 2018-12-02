module Schleuder
  module AuthorizerPolicies
    class KeyPolicy < BasePolicy
      # list is not defined: it must be checked via ListPolicy#list_keys (because we need the list-context).

      def read?
        superadmin? || subscribed?(object.list)
      end

      # create is not defined: it must be checked via ListPolicy#add_keys (because we need the list-context).
      # update is not defined: we can't update keys.

      def delete?
        superadmin? || admin?(object.list)
      end
    end
  end
end
