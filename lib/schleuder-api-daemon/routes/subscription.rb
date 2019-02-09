class SchleuderApiDaemon < Sinatra::Base
  register Sinatra::Namespace

  namespace '/subscriptions' do
    get '.json' do
      filterkeys = subscriptions_controller.get_configurable_attributes + ['list_email', 'email']
      filter = params.select do |param|
        filterkeys.include?(param)
      end

      logger.debug "Subscription filter: #{filter.inspect}"
      if filter['list_email']
        if list = lists_controller.find(filter['list_email'])
          filter['list_id'] = list.id
          filter.delete('list_email')
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
        subscription, messages = subscriptions_controller.subscribe(requested_list_email, attributes, find_key_material)
        set_x_messages(messages)
        logger.debug "subcription: #{subscription.inspect}"
        if subscription.valid?
          logger.debug "Subscribed: #{subscription.inspect}"
          status 201
          json subscription
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

    get '/:email.json' do |email|
      json subscriptions_controller.find(email)
    end

    put '/:id.json' do |id|
      attributes = find_attributes_from_body(subscriptions_controller.get_configurable_attributes)
      required_parameters = subscriptions_controller.get_configurable_attributes
      if attributes.keys.sort != required_parameters.sort
        status 422
        return json(errors: 'The request is missing a required parameter')
      elsif subscriptions_controller.update(id, parsed_body)
        200
      else
        client_error(subscription)
      end
    end

    patch '/:email.json' do |email|
      subscription = subscriptions_controller.update(email, parsed_body)
      if subscription
        200
      else
        client_error(subscription)
      end
    end

    delete '/:email.json' do |email|
      subscription = subscriptions_controller.delete(email)
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
