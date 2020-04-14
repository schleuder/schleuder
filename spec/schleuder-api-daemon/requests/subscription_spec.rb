require 'helpers/api_daemon_spec_helper'
require 'support/matchers/match_json_schema'

describe 'subscription via api' do
  context 'get subscription' do
    it 'returns the subscriptions of the current account and the list email' do
      list = create(:list, email: 'somelist@example.org')
      subscription = create(:subscription, list_id: list.id, admin: true)
      _other_subscription = create(:subscription)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "/lists/#{list.email}/subscriptions.json?", { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body)['data'].length).to be 1
      expect(JSON.parse(last_response.body)['data'][0]['email']).to eq subscription.email
    end

    it 'returns the subscription of the current account filtered by a given fingerprint' do
      list = create(:list, email: 'somelist@example.org')
      subscription = create(:subscription, list_id: list.id, admin: true)
      _other_subscription = create(:subscription)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "/lists/#{list.email}/subscriptions.json?fingerprint=#{subscription.fingerprint}", { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body)['data'].length).to be 1
      expect(JSON.parse(last_response.body)['data'][0]['email']).to eq subscription.email
    end

    it 'returns a 404 when no list with the given email exists' do
      list = create(:list, email: 'somelist@example.org')
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get '/lists/non_existing@example.org/subscriptions.json', { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 404
      expect(last_response.body).to eq '{"error":"List not found.","error_code":"list_not_found"}'
    end

    it 'returns a 403 if no subscription is associated with the account' do
      list = create(:list)
      account = create(:account)
      authorize!(account.email, account.set_new_password!)

      get "/lists/#{list.email}/subscriptions.json", { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq 403
      expect(last_response.body).to eq '{"error":"Not authorized","error_code":"not_authorized"}'
    end
  end

  context 'creating a subscription' do
    it 'doesn\'t subscribe new member without authentication' do
      list = create(:list)
      parameters = { email: 'someone@localhost' }

      expect(list.subscriptions.size).to be(0)

      post "/lists/#{list.email}/subscriptions.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 401
      expect(list.reload.subscriptions.size).to be(0)
    end

    it 'subscribes new member to a list as api_superadmin' do
      list = create(:list)
      authorize_as_api_superadmin!
      parameters = {  email: 'someone@localhost' }

      expect(list.subscriptions.size).to be(0)

      post "/lists/#{list.email}/subscriptions.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }
      list.reload

      expect(last_response.status).to be 200
      expect(list.subscriptions.map(&:email)).to eql(['someone@localhost'])
      expect(list.subscriptions.first.admin?).to be false
      expect(list.subscriptions.first.delivery_enabled).to be true
    end

    it 'subscribes new member to a list as list-admin' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      parameters = { email: 'someone@localhost' }

      post "/lists/#{list.email}/subscriptions.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }
      list.reload

      expect(last_response.status).to be 200
      expect(list.subscriptions.map(&:email)).to include('someone@localhost')
      expect(list.subscriptions.first.admin?).to be false
      expect(list.subscriptions.first.delivery_enabled).to be true
    end

    it 'returns the subscription as json if creation was successful' do
      list = create(:list)
      authorize_as_api_superadmin!
      parameters = { list_email: list.email, email: 'someone@localhost' }

      post "/lists/#{list.email}/subscriptions.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body)['data']).to match_json_schema('subscription')
    end

    it 'returns the subscription and a message if creation was successful but key_material was not valid' do
      list = create(:list)
      authorize_as_api_superadmin!
      parameters = { 
        list_email: list.email, 
        email: 'someone@localhost',
        key_material: 'foo'
      }

      post "/lists/#{list.email}/subscriptions.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body)['data']['email']).to eq 'someone@localhost'
      expect(JSON.parse(last_response.body)['messages']).to eq 'The given key material did not contain any keys!'
    end

    it "doesn't subscribe a new member to a list as subscriber" do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      parameters = { email: 'someone@localhost' }

      expect(list.subscriptions.size).to be(1)
      list.reload

      post "/lists/#{list.email}/subscriptions.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 403
      expect(list.reload.subscriptions.size).to be(1)
    end

    it "doesn't subscribe a new member to a list as unassociated account" do
      list = create(:list)
      account = create(:account)
      authorize!(account.email, account.set_new_password!)
      parameters = { email: 'someone@localhost' }

      expect(list.subscriptions.size).to be(0)
      list.reload

      post "/lists/#{list.email}/subscriptions.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 403
      expect(list.reload.subscriptions.size).to be(0)
    end

    it 'subscribes an admin user as api_superadmin' do
      authorize_as_api_superadmin!
      list = create(:list)
      parameters = { email: 'someone@localhost', admin: true }

      expect(list.subscriptions.size).to be(0)

      post "/lists/#{list.email}/subscriptions.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }
      list.reload

      expect(last_response.status).to be 200
      expect(list.subscriptions.map(&:email)).to eql(['someone@localhost'])
      expect(list.subscriptions.first.admin?).to be true
      expect(list.subscriptions.first.delivery_enabled).to be true
    end

    it 'subscribes an admin user with a truthy value as api_superadmin' do
      authorize_as_api_superadmin!
      list = create(:list)
      parameters = { email: 'someone@localhost', admin: 1 }

      expect(list.subscriptions.size).to be(0)

      post "/lists/#{list.email}/subscriptions.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }
      list.reload

      expect(last_response.status).to be 200
      expect(list.subscriptions.map(&:email)).to eql(['someone@localhost'])
      expect(list.subscriptions.first.admin?).to be true
      expect(list.subscriptions.first.delivery_enabled).to be true
    end

    it 'subscribes an user and unsets delivery flag as api_superadmin' do
      authorize_as_api_superadmin!
      list = create(:list)
      parameters = { email: 'someone@localhost', delivery_enabled: false }

      expect(list.subscriptions.size).to be(0)

      post "/lists/#{list.email}/subscriptions.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }
      list.reload

      expect(last_response.status).to be 200
      expect(list.subscriptions.map(&:email)).to eql(['someone@localhost'])
      expect(list.subscriptions.first.admin?).to be false
      expect(list.subscriptions.first.delivery_enabled).to be false
    end

    it 'returns status code 422 and an error message if user is already subscribed' do
      authorize_as_api_superadmin!
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false, email: 'someone@localhost')
      parameters = { email: 'someone@localhost', delivery_enabled: false }

      post "/lists/#{list.email}/subscriptions.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }
      list.reload

      expect(last_response.status).to be 422
      expect(last_response.body).to eq '{"error":["Email is already subscribed"],"error_code":"validation_error"}'
    end
  end

  context 'delete' do
    it 'unsubscribes members as api_superadmin' do
      list = create(:list)
      subscription = create(:subscription, :list_id => list.id, admin: false)
      authorize_as_api_superadmin!

      expect(list.subscriptions.map(&:email)).to eql([subscription.email])

      delete "/lists/#{list.email}/subscriptions/#{subscription.email}.json"

      expect(last_response.status).to be 200
      expect(list.reload.subscriptions.map(&:email)).to eql([])
    end

    it 'unsubscribes members as list-admin' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      admin_subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: admin_subscription.email)
      authorize!(account.email, account.set_new_password!)

      expect(list.subscriptions.map(&:email)).to include(subscription.email)

      delete "/lists/#{list.email}/subscriptions/#{subscription.email}.json"

      expect(last_response.status).to be 200
      expect(list.reload.subscriptions.map(&:email)).to eql([admin_subscription.email])
    end

    it "doesn't unsubscribes members as subscriber" do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      subscription2 = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription2.email)
      authorize!(account.email, account.set_new_password!)

      delete "/lists/#{list.email}/subscriptions/#{subscription.email}.json"

      expect(last_response.status).to be 403
      expect(list.reload.subscriptions.map(&:email)).to include(subscription.email)
    end

    it "doesn't unsubscribes members as unassociated account" do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      subscription2 = create(:subscription, admin: true)
      account = create(:account, email: subscription2.email)
      authorize!(account.email, account.set_new_password!)

      delete "/lists/#{list.email}/subscriptions/#{subscription.email}.json"

      expect(last_response.status).to be 403
      expect(list.reload.subscriptions.map(&:email)).to include(subscription.email)
    end

    it 'returns a 404 status code when member could not be found' do
      list = create(:list)
      authorize_as_api_superadmin!

      delete "/lists/#{list.email}/subscriptions/nonexisting@example.org.json"

      expect(last_response.status).to eq 404
    end

    it 'returns an error when attempting to unsubscribe the last admin' do
      list = create(:list)
      admin_subscription = create(:subscription, list_id: list.id, admin: true)
      admin_account = create(:account, email: admin_subscription.email)
      authorize!(admin_account.email, admin_account.set_new_password!)

      delete "/lists/#{list.email}/subscriptions/#{admin_subscription.email}.json"

      expect(last_response.status).to be 403
      expect(last_response.body).to eq '{"error":"Last admin cannot be unsubscribed","error_code":"last_admin"}'
    end

  end

  context 'configurable attributes' do
    it 'retuns the configurable_attributes' do
      list = create(:list)
      authorize_as_api_superadmin!

      get "/lists/#{list.email}/subscriptions/configurable_attributes.json"

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body)['data']).to eq ['fingerprint', 'admin', 'delivery_enabled']
    end
  end

  context 'new' do
    it 'returns a new subscription' do
      list = create(:list)
      authorize_as_api_superadmin!

      get "/lists/#{list.email}/subscriptions/new.json"

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body)['data']).to eq Subscription.new.as_json
    end
  end

  context 'getting a subscription' do
    it 'returns a subscription for a given identifier' do
      list = create(:list)
      subscription_email = 'schleuder@example.org'
      list.subscribe(subscription_email, '59C71FB38AEE22E091C78259D06350440F759BD3', false)
      account = create(:account, email: subscription_email)
      authorize!(account.email, account.set_new_password!)

      get "/lists/#{list.email}/subscriptions/#{subscription_email}.json"

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body)['data']['email']).to eq subscription_email
    end

    it 'contains a one line representation of the key in the response body' do
      list = create(:list)
      list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', false)
      account = create(:account, email: 'schleuder@example.org')
      authorize!(account.email, account.set_new_password!)

      get "/lists/#{list.email}/subscriptions/schleuder@example.org.json"

      expect(JSON.parse(last_response.body)['data']['key_summary']).to eq '0x59C71FB38AEE22E091C78259D06350440F759BD3 schleuder@example.org 2016-12-06'
    end

    it 'raises unauthorized if the account is not associated with the list' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id)
      account = create(:account, email: 'foo@example.org')
      authorize!(account.email, account.set_new_password!)

      get "/lists/#{list.email}/subscriptions/#{subscription.email}.json"

      expect(last_response.status).to be 403
    end
  end

  context 'updating a subscription via patch (partial update)' do
    it 'returns 200 if subscription was updated successfully' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      parameters = { email: 'new@example.org' }

      patch "/lists/#{list.email}/subscriptions/#{subscription.email}.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 200
    end

    it 'raises unauthorized if the account is not associated with the list' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id)
      account = create(:account, email: 'foo@example.org')
      authorize!(account.email, account.set_new_password!)
      parameters = { email: 'new@example.org' }

      patch "/lists/#{list.email}/subscriptions/#{subscription.email}.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 403
    end

    it 'returns 200 and an error if parameter is invalid' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      parameters = { email: 'invalid_email_address.org' }

      patch "/lists/#{list.email}/subscriptions/#{subscription.email}.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq 422
      expect(JSON.parse(last_response.body)['error_code']).to eq 'validation_error'
      expect(JSON.parse(last_response.body)['error']).to eq ['Email is not a valid email address']
    end
  end

  context 'updating a subscription via put (replace the resource in its entirety)' do
    it 'returns 200 if subscription was updated successfully' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      parameters = {
        fingerprint: 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE',
        admin: true,
        delivery_enabled: true
      }

      put "/lists/#{list.email}/subscriptions/#{subscription.email}.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 200
    end

    it 'returns an error and status code 422 if a required parameter is missing' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      parameters = {
        fingerprint: 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE',
        admin: true
      }

      put "/lists/#{list.email}/subscriptions/#{subscription.email}.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq 422
      expect(JSON.parse(last_response.body)['error']).to eq 'The request is missing a required parameter'
      expect(JSON.parse(last_response.body)['error_code']).to eq 'parameter_missing'
    end

    it 'returns an error and status code 422 if a parameter is invalid' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      parameters = {
        fingerprint: 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE',
        admin: '', 
        delivery_enabled: true
      }

      put "/lists/#{list.email}/subscriptions/#{subscription.email}.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq 422
      expect(JSON.parse(last_response.body)['error']).to eq ['Admin must be true or false']
      expect(JSON.parse(last_response.body)['error_code']).to eq 'validation_error'
    end

    it 'raises unauthorized if the account is not associated with the list' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id)
      account = create(:account, email: 'foo@example.org')
      authorize!(account.email, account.set_new_password!)
      parameters = {
        fingerprint: 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE',
        admin: true,
        delivery_enabled: true
      }

      put "/lists/#{list.email}/subscriptions/#{subscription.email}.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 403
    end
  end
end
