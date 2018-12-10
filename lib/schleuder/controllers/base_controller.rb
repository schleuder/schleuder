module Schleuder
  class BaseController
    attr_reader :current_account

    def initialize(current_account)
      @current_account = current_account
    end

    def authorize(current_account, resource, action)
      current_account.authorize(resource, action) || raise(Errors::Unauthorized.new)
    end
  end
end
