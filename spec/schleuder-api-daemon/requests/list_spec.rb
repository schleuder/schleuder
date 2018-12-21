require 'helpers/api_daemon_spec_helper'

describe 'lists via api' do
  it "doesn't create a list without authentication" do
    list = build(:list)
    parameters = {
      email: 'new_testlist@example.com',
      fingerprint: list.fingerprint
    }
    num_lists = List.count

    post '/lists.json', parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to be 401
    expect(List.count).to eql(num_lists)
  end

  # Subscriber and list-admin are unassociated already, because no list exists
  # yet, thus we skip the extra test for unassociated admin.

  it "doesn't create a list authorized as subscriber" do
    subscription = create(:subscription, admin: false)
    account = create(:account, email: subscription.email)
    authorize!(account.email, account.set_new_password!)
    list = build(:list)
    parameters = { email: 'new_testlist@example.com', fingerprint: list.fingerprint }
    num_lists = List.count

    post '/lists.json', parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to be 403
    expect(List.count).to eql(num_lists)
  end

  it "doesn't create a list authorized as list-admin" do
    subscription = create(:subscription, admin: true)
    account = create(:account, email: subscription.email)
    authorize!(account.email, account.set_new_password!)
    list = build(:list)
    parameters = { email: 'new_testlist@example.com', fingerprint: list.fingerprint }
    num_lists = List.count

    post '/lists.json', parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to be 403
    expect(List.count).to eql(num_lists)
  end

  it 'creates a list authorized as api_superadmin' do
    authorize_as_api_superadmin!
    list = build(:list)
    parameters = { email: 'new_testlist@example.com', fingerprint: list.fingerprint }
    num_lists = List.count

    post '/lists.json', parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to be 200
    expect(List.count).to eql(num_lists + 1)
    expect(JSON.parse(last_response.body)['fingerprint']).to eql(list.fingerprint)
  end

  it "doesn't show a list without authentication" do
    list = create(:list)

    get "lists/#{list.email}.json"

    expect(last_response.status).to be 401
    expect(last_response.body).to eql('Not authenticated')
  end

  it "doesn't show a list authorized as unassociated account" do
    list = create(:list)
    subscription = create(:subscription, admin: true)
    account = create(:account, email: subscription.email)
    authorize!(account.email, account.set_new_password!)

    get "lists/#{list.email}.json"

    expect(last_response.status).to be 403
    expect(last_response.body).to eql('Not authorized')
  end

  it "doesn't show a list authorized as subscriber with default config" do
    list = create(:list)
    subscription = create(:subscription, list_id: list.id, admin: false)
    account = create(:account, email: subscription.email)
    authorize!(account.email, account.set_new_password!)

    get "lists/#{list.email}.json"

    expect(last_response.status).to be 403
    expect(last_response.body).to eql('Not authorized')
  end

  it 'does show a list authorized as subscriber with modified config' do
    list = create(:list, subscriber_permissions: { 'view-list-config': true })
    subscription = create(:subscription, list_id: list.id, admin: false)
    account = create(:account, email: subscription.email)
    authorize!(account.email, account.set_new_password!)

    get "lists/#{list.email}.json"

    expect(last_response.status).to be 200
    expect(JSON.parse(last_response.body)['email']).to eq list.email
  end

  it 'does show a list authorized as list-admin' do
    list = create(:list)
    subscription = create(:subscription, list_id: list.id, admin: true)
    account = create(:account, email: subscription.email)
    authorize!(account.email, account.set_new_password!)

    get "lists/#{list.email}.json"

    expect(last_response.status).to be 200
    expect(JSON.parse(last_response.body)['email']).to eq list.email
  end

  it 'does show a list authorized as api_superadmin' do
    list = create(:list)
    authorize_as_api_superadmin!

    get "lists/#{list.email}.json"

    expect(last_response.status).to be 200
    expect(JSON.parse(last_response.body)['email']).to eq list.email
  end

  it 'correctly finds a list by email-address that starts with a number' do
    authorize_as_api_superadmin!
    list = create(:list, email: '9list@hostname')
    get "lists/#{list.email}.json"
    expect(last_response.status).to be 200
    expect(JSON.parse(last_response.body)['email']).to eq list.email
  end

  context 'configurable_attributes' do
    it 'returns the configurable_attributes of the list model' do
      authorize_as_api_superadmin!

      get 'lists/configurable_attributes.json'

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body)).to eq([
        'bounces_drop_all', 'bounces_drop_on_headers', 'bounces_notify_admins',
        'forward_all_incoming_to_admins', 'headers_to_meta', 'include_list_headers',
        'include_openpgp_header', 'internal_footer', 'keep_msgid', 'keywords_admin_notify',
        'language', 'log_level', 'logfiles_to_keep', 'max_message_size_kb', 'openpgp_header_preference',
        'public_footer', 'receive_admin_only', 'receive_authenticated_only', 'receive_encrypted_only',
        'receive_from_subscribed_emailaddresses_only', 'receive_signed_only', 'send_encrypted_only',
        'subject_prefix', 'subject_prefix_in', 'subject_prefix_out', 'subscriber_permissions'
      ])
    end
  end

  context 'send_list_key_to_subscriptions' do
    it 'returns true when the user is authorized' do
      authorize_as_api_superadmin!
      list = create(:list)

      post "/lists/#{list.email}/send_list_key_to_subscriptions.json", { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body)['result']).to eq true
    end

    it 'returns not authorized when user is not authorized' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      post "/lists/#{list.email}/send_list_key_to_subscriptions.json", { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 403
      expect(last_response.body).to eql('Not authorized')
    end
  end

  context 'new list' do
    it 'returns a new list' do
      authorize_as_api_superadmin!

      get 'lists/new.json'

      expect(last_response.status).to be 200
      expect(last_response.body).to eq List.new().to_json
    end
  end

  context 'update' do
    it 'returns 403 if list was updated successfully' do
      authorize_as_api_superadmin!
      list = create(:list)
      parameters = { 'email' => 'new_address@example.org' }

      put "lists/#{list.email}.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq 204
    end

    it 'returns not authorized when user is not authorized' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      unauthorized_account = create(:account, email: subscription.email)
      authorize!(unauthorized_account.email, unauthorized_account.set_new_password!)
      parameters = { 'email' => 'new_address@example.org' }

      put "lists/#{list.email}.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 403
      expect(last_response.body).to eql('Not authorized')
    end
  end

  context 'delete' do
    it 'returns 200 if list was deleted successfully' do
      authorize_as_api_superadmin!
      list = create(:list)

      delete "lists/#{list.email}.json"

      expect(last_response.status).to eq 200
    end

    it 'returns not authorized when user is not authorized' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      unauthorized_account = create(:account, email: subscription.email)
      authorize!(unauthorized_account.email, unauthorized_account.set_new_password!)

      delete "lists/#{list.email}.json"

      expect(last_response.status).to be 403
      expect(last_response.body).to eql('Not authorized')
    end
  end
end
