module Schleuder
  module AuthorizerPolicies
    class KeyPolicy < BasePolicy
      # list?() is not defined: it must be checked via ListPolicy#list_keys (we
      # must use the list-object, because we have no key instance in this case.)

      def read?
        superadmin? || admin?(resource.list) || subscriber_permitted?(resource.list, 'view-keys')
      end

      # create?() is not defined: it must be checked via ListPolicy#add_keys
      # (we must use the list-object because we have no key instance in this
      # case).
      
      # update?() is not defined: we can't update keys.

      def delete?
        superadmin? || admin?(resource.list) || subscriber_permitted?(resource.list, 'delete-keys')
      end
    end
  end
end
