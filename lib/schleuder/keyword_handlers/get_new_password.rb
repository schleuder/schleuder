module Schleuder
  module KeywordHandlers
    class GetNewPassword < Base
      handles_request_keyword 'get-new-password', with_arguments: []

      def run
        account = Account.find_or_create_by(email: @mail.signer.email)
        new_password = account.set_new_password!
        t('new_password', email: @mail.signer.email, password: new_password)
      end
    end
  end
end

