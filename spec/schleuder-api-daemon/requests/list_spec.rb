require 'helpers/api_daemon_spec_helper'
require 'support/matchers/match_json_schema'

describe 'lists via api' do
  context 'create list' do
    it 'contains only email addresses in list of lists' do
      authorize_as_api_superadmin!
      list1 = create(:list)
      list2 = create(:list)
  
      get '/lists.json'
  
      expect(last_response.status).to be 200
      expect(last_response.body).to eql([list1.email, list2.email].to_json)
    end
  
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
      expect(JSON.parse(last_response.body)['data']['fingerprint']).to eql(list.fingerprint)
    end

    it 'returns the list in the expected json schema' do
      authorize_as_api_superadmin!
      list = build(:list)
      parameters = { email: 'new_testlist@example.com', fingerprint: list.fingerprint }

      post '/lists.json', parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(JSON.parse(last_response.body)['data']).to match_json_schema('list')
    end

    it 'returns an error and status code 422 if list name is blank' do
      authorize_as_api_superadmin!
      list = build(:list)
      parameters = { fingerprint: list.fingerprint }

      post '/lists.json', parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 422
      expect(JSON.parse(last_response.body)['error']).to eql ({'email' => ["'' is not a valid email address"]})
    end

    it 'returns an error and status code 422 if list name is invalid' do
      authorize_as_api_superadmin!
      list = build(:list)
      parameters = { email: 'invalid' }

      post '/lists.json', parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 422
      expect(JSON.parse(last_response.body)['error']).to eql ({'email' => ["'invalid' is not a valid email address"]})
    end

    it 'returns an error and status code 422 if a parameter validation fails' do
      authorize_as_api_superadmin!
      list = build(:list)
      parameters = { email: 'new_testlist@example.com', fingerprint: 'foo' }

      post '/lists.json', parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 422
      expect(JSON.parse(last_response.body)['error']).to eq ['Fingerprint is not a valid OpenPGP-fingerprint']
    end

    it 'returns status 400 and an error if key generation fails' do
      authorize_as_api_superadmin!
      parameters = { email: 'new_testlist@example.com' }
      allow_any_instance_of(ListBuilder).to receive(:run).with(any_args).and_raise(Errors::KeyGenerationFailed.new('list_dir', 'new_testlist@example.com'))
      
      post '/lists.json', parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }
      
      expect(last_response.status).to eq 400
      expect(JSON.parse(last_response.body)['error']).to eq "Generating the OpenPGP key pair for new_testlist@example.com failed for unknown reasons. Please check the list-directory ('list_dir') and the log-files."
    end

    it 'returns status 200 and a messages if list was created but admin key was invalid' do
      authorize_as_api_superadmin!
      parameters = { 
        email: 'new_testlist@example.com', 
        adminaddress: 'admin@example.org',
        adminfingerprint: '0xB3D190D5235C74E1907EACFE898F2C91E2E6E1F3',
        adminkey: 'invalid'
      }

      post '/lists.json', parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }
      
      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body)['data']['email']).to eq 'new_testlist@example.com'
      expect(JSON.parse(last_response.body)['messages']).to eq 'The given key material did not contain any keys!'
    end
  end

  context 'get list' do
    it "doesn't show a list without authentication" do
      list = create(:list)

      get "lists/#{list.email}.json"

      expect(last_response.status).to be 401
      expect(last_response.body).to eql '{"error":"Not authenticated"}'
    end

    it "doesn't show a list authorized as unassociated account" do
      list = create(:list)
      subscription = create(:subscription, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "lists/#{list.email}.json"

      expect(last_response.status).to be 403
      expect(last_response.body).to eql '{"error":"Not authorized"}'
    end

    it "doesn't show a list authorized as subscriber with default config" do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)
  
      get "lists/#{list.email}.json"
      
      expect(last_response.status).to be 403
      expect(last_response.body).to eq '{"error":"Not authorized"}'
    end

    it 'does show a list authorized as subscriber with modified config' do
      list = create(:list, subscriber_permissions: { 'view-list-config': true })
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "lists/#{list.email}.json"

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body)['data']['email']).to eq list.email
    end

    it 'does show a list authorized as list-admin' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      get "lists/#{list.email}.json"

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body)['data']['email']).to eq list.email
    end

    it 'does show a list authorized as api_superadmin' do
      list = create(:list)
      authorize_as_api_superadmin!

      get "lists/#{list.email}.json"

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body)['data']['email']).to eq list.email
    end

    it 'returns a 404 when list is not existing' do
      authorize_as_api_superadmin!

      get 'lists/nonexisting@example.com.json'

      expect(last_response.status).to be 404
      expect(last_response.body).to eq '{"error":"List not found."}'
    end

    it 'correctly finds a list by email-address that starts with a number' do
      authorize_as_api_superadmin!
      list = create(:list, email: '9list@hostname')
      get "lists/#{list.email}.json"
      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body)['data']['email']).to eq list.email
    end
  end

  context 'configurable_attributes' do
    it 'returns the configurable_attributes of the list model' do
      authorize_as_api_superadmin!

      get 'lists/configurable_attributes.json'

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body)['data']['configurable_attributes']).to eq([
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
      expect(JSON.parse(last_response.body)['data']['result']).to eq true
    end

    it 'returns not authorized when user is not authorized' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      authorize!(account.email, account.set_new_password!)

      post "/lists/#{list.email}/send_list_key_to_subscriptions.json", { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 403
      expect(last_response.body).to eql '{"error":"Not authorized"}'
    end

    it 'returns a 404 when user is authorized and list does not exist' do
      authorize_as_api_superadmin!

      post '/lists/nonexisting@example.com/send_list_key_to_subscriptions.json', { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 404
      expect(last_response.body).to eq '{"error":"List not found."}'
    end
  end

  context 'new list' do
    it 'returns a new list' do
      authorize_as_api_superadmin!

      get 'lists/new.json'

      expect(last_response.status).to be 200
      expect(JSON.parse(last_response.body)['data']).to eq List.new.as_json
    end
  end

  context 'update (via put)' do
    it 'returns 204 if list was updated successfully' do
      authorize_as_api_superadmin!
      list = create(:list)
      parameters = { 'email' => 'new_address@example.org' }

      put "lists/#{list.email}.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq 204
    end

    it 'returns an error status code 400 when list could not be updated' do
      authorize_as_api_superadmin!
      list = create(:list)
      parameters = { email: 'invalid-email-address', fingerprint: '0xB3D190D5235C74E1907EACFE898F2C91E2E6E1F3' }

      put "lists/#{list.email}.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.body).to eq '{"error":["Email is not a valid email address"]}'
      expect(last_response.status).to eq 422
    end

    it 'returns not authorized when user is not authorized' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      unauthorized_account = create(:account, email: subscription.email)
      authorize!(unauthorized_account.email, unauthorized_account.set_new_password!)
      parameters = { 'email' => 'new_address@example.org' }

      put "lists/#{list.email}.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to be 403
      expect(last_response.body).to eql '{"error":"Not authorized"}'
    end
  end

  context 'update (via patch)' do
    it 'returns 204 if list was updated successfully' do
      authorize_as_api_superadmin!
      list = create(:list)
      parameters = { 'email' => 'new_address@example.org' }

      patch "lists/#{list.email}.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq 204
    end

    it 'returns status code 400 when list could not be updated' do
      authorize_as_api_superadmin!
      list = create(:list)
      parameters = { 'email' => 'invalid-email-address' }

      patch "lists/#{list.email}.json", parameters.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq 422
      expect(last_response.body).to eq '{"error":["Email is not a valid email address"]}'
    end
  end

  context 'delete' do
    it 'returns 200 if list was deleted successfully' do
      authorize_as_api_superadmin!
      list = create(:list)

      delete "lists/#{list.email}.json"

      expect(last_response.status).to eq 200
    end

    it 'returns 404 when list could not be found' do
      authorize_as_api_superadmin!

      delete 'lists/nonexisting@example.org.json'

      expect(last_response.status).to eq 404
    end

    it 'returns not authorized when user is not authorized' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      unauthorized_account = create(:account, email: subscription.email)
      authorize!(unauthorized_account.email, unauthorized_account.set_new_password!)

      delete "lists/#{list.email}.json"

      expect(last_response.status).to be 403
      expect(last_response.body).to eql '{"error":"Not authorized"}'
    end
  end
end
