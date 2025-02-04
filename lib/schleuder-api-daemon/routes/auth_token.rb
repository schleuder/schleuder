class SchleuderApiDaemon < Sinatra::Base
  register Sinatra::Namespace

  namespace '/auth_tokens' do
    PUBLIC_ROUTES.push '/auth_tokens/request.json'
    post '/request.json' do
      body = parsed_body
      email = body['email'].to_s.strip
      if email.blank?
        client_error("email required", 422, :payload_error)
      end
      # Allow only one token per emailaddress per time slot (default: 2mins) to slow down abuse.
      if AuthToken.count_recent(email: email) > 0
        halt 429
      end
      auth_token = AuthToken.make!(email: email)

      language = body['language'].to_s.strip
      # Besides english, which is the default, the code currently only supports german language.
      if language == 'de'
        I18n.locale = :de
      end
      verification_url = body['verification_url'].to_s.strip
      # Strip some time as a buffer to allow for human slowness.
      time_limit_minutes = auth_token.valid_for_minutes - 3
      mail_body = if verification_url
                    I18n.t("auth_token.email_body_web",
                           token_value: auth_token.value,
                           time_limit_minutes: time_limit_minutes,
                           verification_url: verification_url)
                  else
                    I18n.t("auth_token.email_body_cli",
                           token_value: auth_token.value,
                           time_limit_minutes: time_limit_minutes)
                  end
      # Send the email.
      # Uses the superadmin as sender and From, because these messages are not
      # so important to justify revealing additional email addresses to avoid
      # bouncing bounces.
      # TODO: Look for a subscription with the given email addresse and use its key!
      superadmin = Conf.superadmin.presence
      mail = Mail.new
      mail.to = auth_token.email
      mail.from = superadmin
      mail.sender = superadmin
      mail[:Errors_To] = superadmin
      mail.subject = I18n.t("auth_token.email_subject")
      mail.body = mail_body
      mail.deliver

      json_body("ok", [I18n.t("auth_token.email_sent", time_limit_minutes: time_limit_minutes)])
    end

    PUBLIC_ROUTES.push '/auth_tokens/redeem.json'
    post '/redeem.json' do
      body = parsed_body
      token_value = body['token'].to_s.strip
      email = body['email'].to_s.strip
      if token_value.blank? || email.blank?
        client_error("token and email required", 422, :payload_error)
      end
      auth_token = AuthToken.find_valid_token(value: token_value, email: email)
      if ! auth_token
        # Use the occasion to delete outdated tokens.
        AuthToken.destroy_outdated
        # Wait another second to discourage scripts that try random tokens.
        sleep 1
        halt 404
      end

      account = Account.find_or_create_by(email: auth_token.email)
      password = account.set_new_password!
      auth_token.destroy!
      json_body(password: password)
    end
  end
end
