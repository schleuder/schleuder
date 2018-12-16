class SchleuderApiDaemon < Sinatra::Base
  register Sinatra::Namespace

  namespace '/keys' do
    get '.json' do
      require_list_id_param
      list = load_list(params[:list_id])
      authorized?(list, :list_keys)
      keys = list.keys.sort_by(&:email).map do |key|
        key_to_hash(key)
      end
      json keys
    end

    post '.json' do
      list = load_list(requested_list_id)
      authorized?(list, :add_keys)
      input = parsed_body['keymaterial']
      if ! input.match('BEGIN PGP')
        input = Base64.decode64(input)
      end
      json list.import_key(input)
    end

    get '/check_keys.json' do
      require_list_id_param
      list = load_list(params[:list_id])
      authorized?(list, :check_keys)
      json result: list.check_keys
    end

    get '/:fingerprint.json' do |fingerprint|
      require_list_id_param
      list = load_list(params[:list_id])
      key = list.key(fingerprint) || halt(404)
      authorized?(key, :read)
      json key_to_hash(key, true)
    end

    delete '/:fingerprint.json' do |fingerprint|
      require_list_id_param
      list = load_list(params[:list_id])
      key = list.key(fingerprint) || halt(404)
      authorized?(key, :delete)
      key.delete!
    end
  end
end
