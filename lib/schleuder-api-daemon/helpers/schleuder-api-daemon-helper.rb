module SchleuderApiDaemonHelper
    def valid_credentials?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      if ! @auth.provided? || ! @auth.basic? || @auth.credentials.blank?
        return false
      end
      email, password = @auth.credentials
      account = Account.find_by(email: email)
      if account.try(:authenticate, password)
        @current_account = account
        true
      else
        false
      end
    end

    def authenticate!
      # Be careful to use path_info() — it can be changed by other filters!
      return if request.path_info == '/status.json'
      if ! valid_credentials?
        headers['WWW-Authenticate'] = 'Basic realm="Schleuder API Daemon"'
        halt 401, json({ error: 'Not authorized' })
      end
    end

    def authorize!(resource, action)
      current_account.authorize!(resource, action) || halt(404)
    end

    def current_account
      @current_account
    end

    def json_body(data, messages=nil)
      json(data: data.as_json, messages: messages)
    end

    def parsed_body
      @parsed_body ||= begin
          b = JSON.parse(request.body.read)
          logger.debug "parsed body: #{b.inspect}"
          b
        end
    end

    def server_error(msg)
      logger.warn msg
      halt(500, json(error: msg))
    end

    def client_error(obj_or_msg, http_code=400, error_code='unexpected_error')
      text = case obj_or_msg
             when String, Symbol
               obj_or_msg.to_s
             when ActiveRecord::Base
               obj_or_msg.errors.full_messages
             else
               obj_or_msg
             end
      logger.error "Sending error to client: #{text.inspect}"
      halt(http_code, json(error: text, error_code: error_code))
    end

    # poor persons type casting
    def cast_param_values
      params.each do |key, value|
        params[key] =
            case value
            when 'true' then true
            when 'false' then false
            when '0' then 0
            when is_an_integer?(value) then value.to_i
            else value
            end
      end
    end

    def interpret_key_import_result(import_result)
      (GPGME::Ctx.new armor: true).interpret_import_result(import_result)
    end

    def find_key_material
      key_material = parsed_body['key_material'].presence
      # By convention key_material is either ASCII or base64-encoded.
      if key_material && ! key_material.match('BEGIN PGP')
        key_material = Base64.decode64(key_material)
      end
      key_material
    end

    def find_attributes_from_body(attribs)
      Array(attribs).inject({}) do |memo, attrib|
        if parsed_body.has_key?(attrib)
          memo[attrib] = parsed_body[attrib]
        end
        memo
      end
    end

    def is_an_integer?(input)
      input.to_s.match(/^[0-9]+$/).present?
    end
end
