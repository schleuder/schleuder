module Schleuder
  class BasePolicy
    attr_reader :account, :object

    class BaseScope
      attr_reader :account

      def initialize(account)
        @account = account
      end
    end


    def initialize(account, object)
      @account = account
      @object = object
    end


    private


    def admin?(list)
      account.is_admin_of_list?(list)
    end

    def superadmin?
      account.api_superadmin?
    end

    # This includes list-admins.
    def subscribed?(list)
      account.is_subscribed_to_list?(list)
    end
  end
end
