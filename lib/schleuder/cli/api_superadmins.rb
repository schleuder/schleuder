module Schleuder
  class ApiSuperadmins < Thor
    include CliHelper

    desc 'list', 'List API-superadmins.'
    def list
      say Account.where(api_superadmin: true).map(&:email).join("\n")
    end

    desc 'add', 'Set an account to be API-superadmin.'
    def add(email)
      set_account_api_superadmin(email, true)
    end

    desc 'remove', 'Set an account to NOT be API-superadmin.'
    def remove(email)
      set_account_api_superadmin(email, false)
    end

    no_commands do
      def set_account_api_superadmin(email, api_superadmin_value)
        account = Account.where(email: email).first
        if account.blank?
          fatal "Account with email '#{email}' not found."
        end
        result = account.update(api_superadmin: api_superadmin_value)
        if result != true
          fatal result
        end
        true
      end
    end
  end
end
