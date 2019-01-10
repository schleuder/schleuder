require 'helpers/api_daemon_spec_helper'

describe 'subscription via api' do
  context 'get subscription' do
    it 'returns the subscription of the current account filtered by a given list email' do
      list = create(:list, email: 'somelist@example.org')
      subscription = create(:subscription, list_id: list.id, admin: true)
      _other_subscription = create(:subscription)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "subscriptions.json?list_id=#{list.email}", { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body).length).to be 1
      expect(JSON.parse(last_response.body)[0]['email']).to eq subscription.email
    end

    it 'returns the subscription of the current account filtered by a given fingerprint' do
      list = create(:list, email: 'somelist@example.org')
      subscription = create(:subscription, list_id: list.id, admin: true)
      _other_subscription = create(:subscription)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "subscriptions.json?fingerprint=#{subscription.fingerprint}", { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body).length).to be 1
      expect(JSON.parse(last_response.body)[0]['email']).to eq subscription.email
    end

    it 'returns a 404 when no list with the given email exists' do
      list = create(:list, email: 'somelist@example.org')
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get 'subscriptions.json?list_id=non_existing@example.org', { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 404
      expect(last_response.body).to eq 'Not found'
    end

    it 'returns a 403 if no subscription is associated with the account' do
      list = create(:list)
      account = create(:account)
      authorize!(account.email, account.set_new_password!)

      get "subscriptions.json?list_id=#{list.email}", { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq 403
      expect(last_response.body).to eq 'Not authorized'
    end
  end

  it 'doesn\'t subscribe new member without authentication' do
    list = create(:list)
    parameters = { list_id: list.id, email: 'someone@localhost' }

    expect(list.subscriptions.size).to be(0)

    post '/subscriptions.json', parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to be 401
    expect(list.reload.subscriptions.size).to be(0)
  end

  it 'subscribes new member to a list as api_superadmin' do
    list = create(:list)
    authorize_as_api_superadmin!
    parameters = { list_id: list.id, email: 'someone@localhost' }

    expect(list.subscriptions.size).to be(0)

    post '/subscriptions.json', parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }
    list.reload

    expect(last_response.status).to be 201
    expect(list.subscriptions.map(&:email)).to eql(['someone@localhost'])
    expect(list.subscriptions.first.admin?).to be false
    expect(list.subscriptions.first.delivery_enabled).to be true
  end

  it 'subscribes new member to a list as list-admin' do
    list = create(:list)
    subscription = create(:subscription, list_id: list.id, admin: true)
    account = create(:account, email: subscription.email)
    authorize!(account.email, account.set_new_password!)
    parameters = { list_id: list.id, email: 'someone@localhost' }

    post '/subscriptions.json', parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }
    list.reload

    expect(last_response.status).to be 201
    expect(list.subscriptions.map(&:email)).to include('someone@localhost')
    expect(list.subscriptions.first.admin?).to be false
    expect(list.subscriptions.first.delivery_enabled).to be true
  end

  it "doesn't subscribe a new member to a list as subscriber" do
    list = create(:list)
    subscription = create(:subscription, list_id: list.id, admin: false)
    account = create(:account, email: subscription.email)
    authorize!(account.email, account.set_new_password!)
    parameters = { list_id: list.id, email: 'someone@localhost' }

    expect(list.subscriptions.size).to be(1)
    list.reload

    post '/subscriptions.json', parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to be 403
    expect(list.reload.subscriptions.size).to be(1)
  end

  it "doesn't subscribe a new member to a list as unassociated account" do
    list = create(:list)
    account = create(:account)
    authorize!(account.email, account.set_new_password!)
    parameters = { list_id: list.id, email: 'someone@localhost' }

    expect(list.subscriptions.size).to be(0)
    list.reload

    post '/subscriptions.json', parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to be 403
    expect(list.reload.subscriptions.size).to be(0)
  end

  it 'subscribes an admin user as api_superadmin' do
    authorize_as_api_superadmin!
    list = create(:list)
    parameters = { list_id: list.id, email: 'someone@localhost', admin: true }

    expect(list.subscriptions.size).to be(0)

    post '/subscriptions.json', parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }
    list.reload

    expect(last_response.status).to be 201
    expect(list.subscriptions.map(&:email)).to eql(['someone@localhost'])
    expect(list.subscriptions.first.admin?).to be true
    expect(list.subscriptions.first.delivery_enabled).to be true
  end

  it 'subscribes an admin user with a truthy value as api_superadmin' do
    authorize_as_api_superadmin!
    list = create(:list)
    parameters = { list_id: list.id, email: 'someone@localhost', admin: 1 }

    expect(list.subscriptions.size).to be(0)

    post '/subscriptions.json', parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }
    list.reload

    expect(last_response.status).to be 201
    expect(list.subscriptions.map(&:email)).to eql(['someone@localhost'])
    expect(list.subscriptions.first.admin?).to be true
    expect(list.subscriptions.first.delivery_enabled).to be true
  end

  it 'subscribes an user and unsets delivery flag as api_superadmin' do
    authorize_as_api_superadmin!
    list = create(:list)
    parameters = { list_id: list.id, email: 'someone@localhost', delivery_enabled: false }

    expect(list.subscriptions.size).to be(0)

    post '/subscriptions.json', parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }
    list.reload

    expect(last_response.status).to be 201
    expect(list.subscriptions.map(&:email)).to eql(['someone@localhost'])
    expect(list.subscriptions.first.admin?).to be false
    expect(list.subscriptions.first.delivery_enabled).to be false
  end

  it 'unsubscribes members as api_superadmin' do
    list = create(:list)
    subscription = create(:subscription, :list_id => list.id)
    authorize_as_api_superadmin!

    expect(list.subscriptions.map(&:email)).to eql([subscription.email])

    delete "/subscriptions/#{subscription.email}.json"

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

    delete "/subscriptions/#{subscription.email}.json"

    expect(last_response.status).to be 200
    expect(list.reload.subscriptions.map(&:email)).to eql([admin_subscription.email])
  end

  it "doesn't unsubscribes members as subscriber" do
    list = create(:list)
    subscription = create(:subscription, list_id: list.id, admin: false)
    subscription2 = create(:subscription, list_id: list.id, admin: false)
    account = create(:account, email: subscription2.email)
    authorize!(account.email, account.set_new_password!)

    delete "/subscriptions/#{subscription.email}.json"

    expect(last_response.status).to be 403
    expect(list.reload.subscriptions.map(&:email)).to include(subscription.email)
  end

  it "doesn't unsubscribes members as unassociated account" do
    list = create(:list)
    subscription = create(:subscription, list_id: list.id, admin: false)
    subscription2 = create(:subscription, admin: true)
    account = create(:account, email: subscription2.email)
    authorize!(account.email, account.set_new_password!)

    delete "/subscriptions/#{subscription.email}.json"

    expect(last_response.status).to be 403
    expect(list.reload.subscriptions.map(&:email)).to include(subscription.email)
  end

  context 'configurable attributes' do
    it 'retuns the configurable_attributes' do
      authorize_as_api_superadmin!

      get '/subscriptions/configurable_attributes.json'

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body)).to eq ['fingerprint', 'admin', 'delivery_enabled']
    end
  end

  context 'new' do
    it 'returns a new subscription' do
      authorize_as_api_superadmin!

      get 'subscriptions/new.json'

      expect(last_response.status).to be 200
      expect(last_response.body).to eq Subscription.new().to_json
    end
  end

  context 'getting a subscription' do
    it 'returns a subscription for a given identifier' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "/subscriptions/#{subscription.email}.json"

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body)['email']).to eq subscription.email
    end

    it 'raises unauthorized if the account is not associated with the list' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id)
      account = create(:account, email: 'foo@example.org')
      authorize!(account.email, account.set_new_password!)

      get "/subscriptions/#{subscription.email}.json"

      expect(last_response.status).to be 403
    end
  end

  context 'updating a subscription via patch (partial update)' do
    it 'returns 200 if subscription was updated successfully' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      parameters = { list_id: list.id, email: 'new@example.org' }

      patch "/subscriptions/#{subscription.email}.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 200
    end

    it 'raises unauthorized if the account is not associated with the list' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id)
      account = create(:account, email: 'foo@example.org')
      authorize!(account.email, account.set_new_password!)
      parameters = { list_id: list.id, email: 'new@example.org' }

      patch "/subscriptions/#{subscription.email}.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 403
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

      put "/subscriptions/#{subscription.email}.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 200
    end

    it 'returns an error and status code 400 if a required parameter is missing' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
      parameters = {
        fingerprint: 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE',
        admin: true
      }

      put "/subscriptions/#{subscription.email}.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 422
      expect(JSON.parse(last_response.body)['errors']).to eq 'The request is missing a required parameter'
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

      put "/subscriptions/#{subscription.email}.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 403
    end
  end
end
