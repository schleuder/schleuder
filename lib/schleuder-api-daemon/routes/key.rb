class SchleuderApiDaemon < Sinatra::Base
  register Sinatra::Namespace

  namespace "/keys" do
    get ".json" do
      require_list_email_param("list_email")
      keys = keys_controller.find_all(params[:list_email])
      keys_hash = keys.sort_by(&:email).map do |key|
        key_to_hash(key)
      end
      json keys_hash
    end

    post ".json" do
      input = parsed_body["keymaterial"]
      if !input.match("BEGIN PGP")
        input = Base64.decode64(input)
      end
      import_result = keys_controller.import(requested_list_email, input)
      keys = []
      messages = []
      import_result.imports.each do |import_status|
        if import_status.action == "error"
          messages << "The key with the fingerprint #{import_status.fingerprint} could not be imported for unknown reasons"
        else
          key = list(requested_list_id).gpg.find_distinct_key(import_status.fingerprint)
          if key
            keys << key_to_hash(key).merge({import_action: import_status.action})
          end
        end
      end
      set_x_messages(messages)
      # Use a Hash as single response object to stay more REST-like. (also,
      # ActiveResource chokes if we return an array here).
      # The 'type' attribute is only necessary to keep ActiveResource from
      # complaining about "expected attributes to be able to convert to Hash",
      # which for some reason is raised without it (or some other, similar
      # attribute).
      json({type: "keys", keys: keys})
    end

    get "/check_keys.json" do
      require_list_email_param("list_email")
      json result: keys_controller.check(params[:list_email])
    end

    get "/:fingerprint.json" do |fingerprint|
      require_list_email_param("list_email")
      key = keys_controller.find(params[:list_email], fingerprint)
      json key_to_hash(key, true)
    end

    delete "/:fingerprint.json" do |fingerprint|
      require_list_email_param("list_email")
      keys_controller.delete(params[:list_email], fingerprint)
    end
  end

  private

  def keys_controller
    Schleuder::KeysController.new(current_account)
  end
end
