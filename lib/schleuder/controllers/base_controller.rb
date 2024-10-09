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
      List.find_by(email: email.to_s) || raise(Errors::ListNotFound.new(email))
    end

    def t(key, **)
      underscored_name = self.class.name.demodulize.underscore
      I18n.t("#{underscored_name}.#{key}", **)
    end
  end
end
