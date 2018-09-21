class SchleuderApiDaemon < Sinatra::Base
  register Sinatra::Namespace

  namespace '/lists' do
    get '.json' do
      json List.all, include: :subscriptions
    end

    post '.json' do
      listname = parsed_body['email']
      fingerprint = parsed_body['fingerprint']
      adminaddress = parsed_body['adminaddress']
      adminfingerprint = parsed_body['adminfingerprint']
      adminkey = parsed_body['adminkey']
      list, messages = ListBuilder.new({email: listname, fingerprint: fingerprint}, adminaddress, adminfingerprint, adminkey).run
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
      json(List.configurable_attributes) + "\n"
    end

    post '/send_list_key_to_subscriptions.json' do
      json(result: list.send_list_key_to_subscriptions)
    end

    get '/new.json' do
      json List.new
    end
    
    get '/:id.json' do |id|
      json list(id)
    end

    put '/:id.json' do |id|
      list = list(id)
      if list.update(parsed_body)
        204
      else
        client_error(list)
      end
    end

    patch '/:id.json' do |id|
      list = list(id)
      if list.update(parsed_body)
        204
      else
        client_error(list)
      end
    end

    delete '/:id.json' do |id|
      list = list(id)
      if list.destroy
        200
      else
        client_error(list)
      end
    end
  end
end
