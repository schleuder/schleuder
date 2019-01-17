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

    def to_query_args(identifier)
      if is_an_integer?(identifier)
        {id: identifier.to_i}
      else
        {email: identifier.to_s}
      end
    end

    def is_an_integer?(input)
      input.to_s.match(/^[0-9]+$/).present?
    end
  end
end
