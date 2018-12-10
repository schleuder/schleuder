class SchleuderApiDaemon < Sinatra::Base
  register Sinatra::Namespace

  namespace '/lists' do
    get '.json' do
      json(lists_controller.lists, include: :subscriptions)
    end

    post '.json' do
      listname = parsed_body['email']
      fingerprint = parsed_body['fingerprint']
      adminaddress = parsed_body['adminaddress']
      adminfingerprint = parsed_body['adminfingerprint']
      adminkey = parsed_body['adminkey']
      list, messages = lists_controller.create(listname, fingerprint, adminaddress, adminfingerprint, adminkey)
      if list.nil?
        client_error(messages, 422)
      elsif ! list.valid?
        client_error(list, 422)
      else
        set_x_messages(messages)
        body json(list)
      end
    end

    get '/configurable_attributes.json' do
      json(lists_controller.get_configurable_attributes) + "\n"
    end

    post '/send_list_key_to_subscriptions.json' do
      require_list_id_param
      json(result: lists_controller.send_list_key_to_subscriptions(params[:list_id]))
    end

    get '/new.json' do
      json lists_controller.new
    end

    get '/:id.json' do |id|
      json lists_controller.list(id)
    end

    put '/:id.json' do |id|
      if lists_controller.update(id, parsed_body)
        204
      else
        client_error(list)
      end
    end

    patch '/:id.json' do |id|
      if lists_controller.update(id, parsed_body)
        204
      else
        client_error(list)
      end
    end

    delete '/:id.json' do |id|
      if lists_controller.delete(id)
        200
      else
        client_error(list)
      end
    end
  end

  def lists_controller
    Schleuder::ListsController.new(current_account)
  end
end
