class SchleuderApiDaemon < Sinatra::Base
  register Sinatra::Namespace

  namespace '/lists' do
    get '/:list_email/subscriptions.json' do |list_email|
      filterkeys = subscriptions_controller.get_configurable_attributes + ['email']
      filter = params.select do |param|
        filterkeys.include?(param)
      end
      logger.debug "Subscription filter: #{filter.inspect}"

      if !list = lists_controller.find(list_email)
        status 404
        return json(errors: 'No such list')
      end
      json subscriptions_controller.find_all(list_email, filter)
    end


    post '/:list_email/subscriptions.json' do |list_email|
      begin
        attributes = find_attributes_from_body(%w[email fingerprint admin delivery_enabled])
        subscription, messages = subscriptions_controller.subscribe(list_email, attributes, find_key_material)
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

    get '/:list_email/subscriptions/configurable_attributes.json' do
      json(subscriptions_controller.get_configurable_attributes) + "\n"
    end

    get '/:list_email/subscriptions/new.json' do
      json subscriptions_controller.new_subscription
    end

    get '/:list_email/subscriptions/:email.json' do |list_email, email|
      json subscriptions_controller.find(list_email, email)
    end

    put '/:list_email/subscriptions/:email.json' do |list_email, email|
      attributes = find_attributes_from_body(subscriptions_controller.get_configurable_attributes)
      required_parameters = subscriptions_controller.get_configurable_attributes
      if attributes.keys.sort != required_parameters.sort
        status 422
        return json(errors: 'The request is missing a required parameter')
      elsif subscriptions_controller.update(list_email, email, parsed_body)
        200
      else
        client_error(subscription)
      end
    end

    patch '/:list_email/subscriptions/:email.json' do |list_email, email|
      subscription = subscriptions_controller.update(list_email, email, parsed_body)
      if subscription
        200
      else
        client_error(subscription)
      end
    end

    delete '/:list_email/subscriptions/:email.json' do |list_email, email|
      subscription = subscriptions_controller.delete(list_email, email)
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
