class SchleuderApiDaemon < Sinatra::Base
  register Sinatra::Namespace

  namespace '/lists' do
    get '/:list_email/subscriptions.json' do |list_email|
      filterkeys = subscriptions_controller.get_configurable_attributes + ['email']
      filter = params.select do |param|
        filterkeys.include?(param)
      end
      logger.debug "Subscription filter: #{filter.inspect}"

      json subscriptions_controller.find_all(list_email, filter)
    end

    post '/:list_email/subscriptions.json' do |list_email|
      attributes = find_attributes_from_body(%w[email fingerprint admin delivery_enabled])
      subscription, messages = subscriptions_controller.subscribe(list_email, attributes, find_key_material)
      set_x_messages(messages)
      logger.debug "subcription: #{subscription.inspect}"
      if subscription.valid?
        logger.debug "Subscribed: #{subscription.inspect}"
        json subscription
      else
        client_error(subscription, 422)
      end
    end

    get '/:list_email/subscriptions/configurable_attributes.json' do
      json(subscriptions_controller.get_configurable_attributes) + "\n"
    end

    get '/:list_email/subscriptions/new.json' do
      json subscriptions_controller.new_subscription
    end

    get '/:list_email/subscriptions/:email.json' do |list_email, email|
      subscription = subscriptions_controller.find(list_email, email)
      key_summary = subscription.key.summary

      json subscription.attributes.merge(key_summary: key_summary)
    end

    put '/:list_email/subscriptions/:email.json' do |list_email, email|
      attributes = find_attributes_from_body(subscriptions_controller.get_configurable_attributes)
      required_parameters = subscriptions_controller.get_configurable_attributes
      if attributes.keys.sort != required_parameters.sort
        status 422
        return json(error: 'The request is missing a required parameter')
      end
      subscription = subscriptions_controller.update(list_email, email, parsed_body)
      if subscription.valid?
        200
      else
        client_error(subscription)
      end
    end

    patch '/:list_email/subscriptions/:email.json' do |list_email, email|
      subscription = subscriptions_controller.update(list_email, email, parsed_body)
      if subscription.valid?
        200
      else
        client_error(subscription)
      end
    end

    delete '/:list_email/subscriptions/:email.json' do |list_email, email|
      subscription = subscriptions_controller.delete(list_email, email)
      if subscription
        200
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
