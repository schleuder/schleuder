class SchleuderApiDaemon < Sinatra::Base
  register Sinatra::Namespace

  namespace '/keys' do
    get '.json' do
      require_list_email_param('list_email')
      keys = keys_controller.find_all(params[:list_email])
      keys_hash = keys.sort_by(&:email).map do |key|
        key_to_hash(key)
      end
      json keys_hash
    end

    post '.json' do
      input = parsed_body['keymaterial']
      if !input.match('BEGIN PGP')
        input = Base64.decode64(input)
      end
      json keys_controller.import(requested_list_email, input)
    end

    get '/check_keys.json' do
      require_list_email_param('list_email')
      json result: keys_controller.check(params[:list_email])
    end

    get '/:fingerprint.json' do |fingerprint|
      require_list_email_param('list_email')
      key = keys_controller.find(params[:list_email], fingerprint)
      json key_to_hash(key, true)
    end

    delete '/:fingerprint.json' do |fingerprint|
      require_list_email_param('list_email')
      keys_controller.delete(params[:list_email], fingerprint)
    end
  end

  private

  def keys_controller
    Schleuder::KeysController.new(current_account)
  end
end
