module Schleuder
  module RequestPlugins
    def self.get_new_api_password(arguments, list, mail)
      account = Account.find_or_create_by(email: mail.signer.email)
      new_password = account.set_new_password!
      # TODO: I18n.
      "Your new API-password: #{new_password}"
    end
  end
end

