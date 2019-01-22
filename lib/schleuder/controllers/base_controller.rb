module Schleuder
  class BaseController
    attr_reader :current_account

    def initialize(current_account)
      @current_account = current_account
    end

    private

    def authorize!(resource, action)
      current_account.authorize!(resource, action)
    end

    def get_list(email)
      List.find_by(email: email.to_s)
    end
  end
end
