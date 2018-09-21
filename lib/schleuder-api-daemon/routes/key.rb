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
      json list(requested_list_id).import_key(input)
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
