module Schleuder
  module KeywordHandlers
    class GetNewPasswordFor < Base
      handles_request_keyword 'get-new-password-for', with_arguments: [Conf::EMAIL_REGEXP]

      def run
        # Beware: the account might not exist yet.
        if ! @mail.signer.admin? && ! @mail.signer.account.try(:api_superadmin?)
          return t('admins_only')
        end

        # TODO: Do we still need this check?
        if @arguments.size != 1
          return t('argument_size_mismatch')
        end

        email = @arguments.first

        # This raises an exception if the subscription is not present. That
        # exception is caught by the KeywordHandlersRunner.
        subscriptions_controller.find(@mail.list.email, email)

        account = Account.find_or_create_by(email: email)
        new_password = account.set_new_password!
        t('new_password', email: email, password: new_password)
      end
    end
  end
end

