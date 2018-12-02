class SchleuderApiDaemon < Sinatra::Base
  register Sinatra::Namespace

  namespace '/subscriptions' do
    get '.json' do
      filterkeys = Subscription.configurable_attributes + ['list_id', 'email']
      filter = params.select do |param|
        filterkeys.include?(param)
      end

      logger.debug "Subscription filter: #{filter.inspect}"
      if filter['list_id'] && ! is_an_integer?(filter['list_id'])
        # Value is an email-address
        if list = lists_controller.find(filter['list_id'])
          filter['list_id'] = list.id
        else
          status 404
          return json(errors: 'No such list')
        end
      end

      json subscriptions_controller.find_all(filter)
    end

    post '.json' do
      begin
        attributes = find_attributes_from_body(%w[email fingerprint admin delivery_enabled])
        subscription, messages = subscriptions_controller.subscribe(requested_list_id, attributes, find_key_material)
        set_x_messages(messages)
        logger.debug "subcription: #{subscription.inspect}"
        if subscription.valid?
          logger.debug "Subscribed: #{subscription.inspect}"
          # TODO: why redirect instead of respond with result?
          redirect to("/subscriptions/#{subscription.id}.json"), 201
        else
          client_error(subscription, 422)
        end
      rescue ActiveRecord::RecordNotUnique
        logger.error 'Already subscribed'
        status 422
        json errors: {email: ['is already subscribed']}
      end
    end

    get '/configurable_attributes.json' do
      json(subscriptions_controller.get_configurable_attributes) + "\n"
    end

    get '/new.json' do
      json subscriptions_controller.new_subscription
    end

    get '/:id.json' do |id|
      json subscriptions_controller.find(id)
    end

    put '/:id.json' do |id|
      sub = load_subscription(id)
      authorized?(sub, :update)
      list = sub.list
      args = find_attributes_from_body(%w[email fingerprint admin delivery_enabled])
      fingerprint, messages = list.import_key_and_find_fingerprint(find_key_material)
      set_x_messages(messages)
      # For an already existing subscription, only update fingerprint if a
      # new one has been selected from the upload.
      if fingerprint.present?
        args['fingerprint'] = fingerprint
      end
      if sub.update(args)
        200
      else
        client_error(sub, 422)
      end
    end

    patch '/:id.json' do |id|
      subscription = subscriptions_controller.update(id, parsed_body)
      if subscription
        200
      else
        client_error(subscription)
      end
    end

    delete '/:id.json' do |id|
      subscription = subscriptions_controller.delete(id)
      if subscription
        200
      else
        client_error(subscription)
      end
    end
  end

  private

  def subscriptions_controller
    Schleuder::SubscriptionsController.new(current_account)
  end

  def lists_controller
    Schleuder::ListsController.new(current_account)
  end
end
