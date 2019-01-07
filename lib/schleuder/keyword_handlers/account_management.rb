module Schleuder
  module KeywordHandlers
    class AccountManagement < Base
      handles_request_keyword 'get-new-password', with_method: 'get_new_password'
      handles_request_keyword 'get-new-password-for', with_method: 'get_new_password_for'

      def get_new_password
        set_new_password(@mail.signer.email)
      end

      def get_new_password_for
        error = check_preconditions
        return error if error

        email = @arguments.first

        subscription = Subscription.where(email: email, list_id: @list.id).first
        if subscription.blank?
          return I18n.t('keyword_handlers.account_management.subscription_not_found')
        end

        set_new_password(email)
      end

      
      private

      def check_preconditions
        # Beware: the account might not exist yet.
        if ! @mail.signer.admin? && ! @mail.signer.account.try(:api_superadmin?)
          return I18n.t('keyword_handlers.account_management.admins_only')
        end

        if @arguments.size != 1
          return I18n.t('keyword_handlers.account_management.argument_size_mismatch')
        end
      end

      def set_new_password(email)
        account = Account.find_or_create_by(email: email)
        new_password = account.set_new_password!
        I18n.t('keyword_handlers.account_management.new_password', email: email, password: new_password)
      end
    end
  end
end
