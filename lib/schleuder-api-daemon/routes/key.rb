class SchleuderApiDaemon < Sinatra::Base
  register Sinatra::Namespace

  namespace '/keys' do
    get '.json' do
      keys = list.keys.sort_by(&:email).map do |key|
        key_to_hash(key)
      end
      json keys
    end

    post '.json' do
      input = parsed_body['keymaterial']
      if ! input.match('BEGIN PGP')
        input = Base64.decode64(input)
      end
      @list = list(requested_list_id)
      import_result = @list.import_key(input)
      keys = []
      messages = []
      import_result.imports.each do |import_status|
        if import_status.action == 'error'
          messages << "The key with the fingerprint #{import_status.fingerprint} could not be imported for unknown reasons"
        else
          key = @list.gpg.find_distinct_key(import_status.fingerprint)
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
      json({type: 'keys', keys: keys})
    end

    get '/check_keys.json' do
      json result: list.check_keys
    end

    get '/:fingerprint.json' do |fingerprint|
      if key = list.key(fingerprint)
        json key_to_hash(key, true)
      else
        404
      end
    end

    delete '/:fingerprint.json' do |fingerprint|
      if list.delete_key(fingerprint)
        200
      else
        404
      end
    end
  end
end
