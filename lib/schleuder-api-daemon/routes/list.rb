class SchleuderApiDaemon < Sinatra::Base
  register Sinatra::Namespace

  namespace '/lists' do
    get '.json' do
      # Do *not* show any further details about a list unless
      # lists_controller.find(list.email) returns the list-object!
      json(lists_controller.find_all.map(&:email))
    end

    post '.json' do
      list_email = parsed_body['email']
      fingerprint = parsed_body['fingerprint']
      adminaddress = parsed_body['adminaddress']
      adminfingerprint = parsed_body['adminfingerprint']
      adminkey = parsed_body['adminkey']
      list, messages = lists_controller.create(list_email, fingerprint, adminaddress, adminfingerprint, adminkey)
      if list.nil?
        client_error(messages, 422, :validation_error)
      elsif ! list.valid?
        client_error(list, 422, :validation_error)
      else
        json_body(list, messages)
      end
    end

    get '/configurable_attributes.json' do
      json_body(configurable_attributes: lists_controller.get_configurable_attributes)
    end

    post '/:list_email/send_list_key_to_subscriptions.json' do |list_email|
      json_body(result: lists_controller.send_list_key_to_subscriptions(list_email))
    end

    get '/new.json' do
      json_body(lists_controller.new_list)
    end

    get '/:email.json' do |email|
      json_body(lists_controller.find(email))
    end

    put '/:email.json' do |email|
      list = lists_controller.update(email, parsed_body)
      if list.valid?
        204
      else
        client_error(list, 422, :validation_error)
      end
    end

    patch '/:email.json' do |email|
      list = lists_controller.update(email, parsed_body)
      if list.valid?
        204
      else
        client_error(list, 422, :validation_error)
      end
    end

    delete '/:email.json' do |email|
      list = lists_controller.find(email)
      if lists_controller.delete(email)
        200
      end
    end
  end

  def lists_controller
    Schleuder::ListsController.new(current_account)
  end
end
