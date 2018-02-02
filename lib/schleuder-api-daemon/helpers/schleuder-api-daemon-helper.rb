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
        halt 401, "Not authorized\n"
      end
    end

    def authorize(resource, action)
      current_account.authorize(resource, action) || halt(403)
    end

    def current_account
      @current_account
    end

    def make_query_args(identifier)
      if is_an_integer?(identifier)
        {id: identifier.to_i}
      else
        {email: identifier.to_s}
      end
    end

    def require_list_id_param(msg='Need "list_id" query-parameter')
      params[:list_id].presence || client_error(msg)
    end

    def load_list(identifier)
      query_args = make_query_args(identifier)
      List.where(query_args).first || halt(404)
    end

		def load_subscription(identifier)
      query_args = make_query_args(identifier)
      if is_an_integer?(identifier)
        query_base = Subscription
      else require_list_id_param("Parameter list_id is required when using email as identifier for subscriptions.")
        list = load_list(params[:list_id])
        query_base = list.subscriptions
      end
      query_base.where(query_args).first || halt(404)
		end

    def subscription(id_or_email)
      if is_an_integer?(id_or_email)
        sub = Subscription.where(id: id_or_email.to_i).first
      else
        # Email
        if params[:list_id].blank?
          client_error 'Parameter list_id is required when using email as identifier for subscriptions.'
        else
          sub = list.subscriptions.where(email: id_or_email).first
        end
      end
      sub || halt(404)
    end

    def requested_list_id
      # ActiveResource doesn't want to use query-params with create(), so here
      # list_id might be included in the request-body.
      params['list_id'] || parsed_body['list_id'] || client_error('Need list_id')
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

    # TODO: unify error messages. This method currently sends an old error format. See <https://github.com/rails/activeresource/blob/d6a5186/lib/active_resource/base.rb#L227>.
    def client_error(obj_or_msg, http_code=400)
      text = case obj_or_msg
             when String, Symbol
               obj_or_msg.to_s
             when ActiveRecord::Base
               obj_or_msg.errors.full_messages
             else
               obj_or_msg
             end
      logger.error "Sending error to client: #{text.inspect}"
      halt(http_code, json(errors: text))
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

    def key_to_hash(key, include_keydata=false)
      hash = {
        fingerprint: key.fingerprint,
        email: key.email,
        expiry: key.expires,
        generated_at: key.generated_at,
        primary_uid: key.primary_uid.uid,
        summary: key.summary,
        trust_issues: key.usability_issue
      }
      if include_keydata
        hash[:description] = key.to_s
        hash[:ascii] = key.armored
      end
      hash
    end

    def set_x_messages(messages)
      if messages.present?
        headers 'X-Messages' => Array(messages).join(' // ').gsub(/\n/, ' // ')
      end
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
