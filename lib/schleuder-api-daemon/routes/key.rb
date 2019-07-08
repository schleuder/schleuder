class SchleuderApiDaemon < Sinatra::Base
  register Sinatra::Namespace

  namespace "/lists" do
    get "/:list_email/keys.json" do |list_email|
      keys = keys_controller.find_all(list_email)
      keys_hash = keys.sort_by(&:email).map do |key|
        key_hash = key_to_hash(key)
        if authorized_to_read_subscriptions?(list_email)
          subscription = subscription(list_email, key.fingerprint)
          if subscription
            key_hash.merge!(subscription: subscription.email)
          end
        end
        key_hash
      end
      json keys_hash
    end

    post "/:list_email/keys.json" do |list_email|
      input = parsed_body["keymaterial"]
      if !input.match("BEGIN PGP")
        input = Base64.decode64(input)
      end
      import_result = keys_controller.import(list_email, input)
      keys = []
      messages = []
      import_result.imports.each do |import_status|
        if import_status.action == "error"
          messages << "The key with the fingerprint #{import_status.fingerprint} could not be imported for unknown reasons"
        else
          key = list(requested_list_id).gpg.find_distinct_key(import_status.fingerprint)
          if key
            keys << key_to_hash(key).merge({import_action: import_status.action})
          end
        end
      end
      set_x_messages(messages)
      # Use a Hash as single response object to stay more REST-like. (also,
      # ActiveResource chokes if we return an array here).
      # The 'type' attribute is only necessary to keep ActiveResource from
      # complaining about "expected attributes to be able to convert to Hash",
      # which for some reason is raised without it (or some other, similar
      # attribute).
      json({type: "keys", keys: keys})
    end

    get "/:list_email/keys/check.json" do |list_email|
      json result: keys_controller.check(list_email)
    end

    get "/:list_email/keys/:fingerprint.json" do |list_email, fingerprint|
      key = keys_controller.find(list_email, fingerprint)
      key_hash = key_to_hash(key, true)
      if authorized_to_read_subscriptions?(list_email)
        subscription = subscription(list_email, key.fingerprint)
        if subscription
          key_hash.merge!(subscription: subscription.email)
        end
      end
      json key_hash
    end

    delete "/:list_email/keys/:fingerprint.json" do |list_email, fingerprint|
      keys_controller.delete(list_email, fingerprint)
    end
  end

  private

  def keys_controller
    Schleuder::KeysController.new(current_account)
  end

  def lists_controller
    Schleuder::ListsController.new(current_account)
  end

  def subscriptions_controller
    Schleuder::SubscriptionsController.new(current_account)
  end

  def subscription(list_email, fingerprint)
    subscription = subscriptions_controller.find_all(list_email, {fingerprint: fingerprint}).first
    subscription ||= nil
  end
  
  def authorized_to_read_subscriptions?(list_email)
    list = lists_controller.find(list_email) 
    authorize!(list, :list_subscriptions)
    return true
  rescue Errors::Unauthorized
    return false
  end

  def key_to_hash(key, include_keydata=false)
    hash = {
      fingerprint: key.fingerprint,
      email: key.email,
      expiry: key.expires,
      generated_at: key.generated_at,
      primary_uid: key.primary_uid.uid,
      summary: key.summary,
      trust_issues: key.usability_issue,
    }
    if include_keydata
      hash[:description] = key.to_s
      hash[:ascii] = key.armored
    end
    hash
  end
end
