class SchleuderApiDaemon < Sinatra::Base
  register Sinatra::Namespace

  namespace '/lists' do
    get '/:list_email/keys.json' do |list_email|
      keys = keys_controller.find_all(list_email)
      keys_hash = keys.sort_by(&:email).map do |key|
        key_to_hash(key)
      end
      json keys_hash
    end

    post '/:list_email/keys.json' do |list_email|
      input = parsed_body['keymaterial']
      if !input.match('BEGIN PGP')
        input = Base64.decode64(input)
      end
      json keys_controller.import(list_email, input)
    end

    get '/:list_email/keys/check.json' do |list_email|
      json result: keys_controller.check(list_email)
    end

    get '/:list_email/keys/:fingerprint.json' do |list_email, fingerprint|
      key = keys_controller.find(list_email, fingerprint)
      json key_to_hash(key, true)
    end

    delete '/:list_email/keys/:fingerprint.json' do |list_email, fingerprint|
      keys_controller.delete(list_email, fingerprint)
    end
  end

  private

  def keys_controller
    Schleuder::KeysController.new(current_account)
  end
end
