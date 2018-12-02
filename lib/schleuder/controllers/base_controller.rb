module Schleuder
  class BaseController
    attr_reader :current_account

    def initialize(current_account)
      @current_account = current_account
    end

    private

    def authorized?(resource, action)
      current_account.authorized?(resource, action) || raise(Errors::Unauthorized.new)
    end

    def get_list_by_id_or_email(identifier)
      query_args = to_query_args(identifier)
      List.where(query_args).first
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
