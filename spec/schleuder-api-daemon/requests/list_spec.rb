require 'helpers/api_daemon_spec_helper'

describe 'lists via api' do
  it "doesn't create a list without authentication" do
    list = build(:list)
    parameters = {
      email: 'new_testlist@example.com',
      fingerprint: list.fingerprint
    }
    num_lists = List.count

    post '/lists.json', parameters.to_json

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

    post '/lists.json', parameters.to_json

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

    post '/lists.json', parameters.to_json

    expect(last_response.status).to be 403
    expect(List.count).to eql(num_lists)
  end

  it 'creates a list authorized as api_superadmin' do
    authorize_as_api_superadmin!
    list = build(:list)
    parameters = { email: 'new_testlist@example.com', fingerprint: list.fingerprint }
    num_lists = List.count

    post '/lists.json', parameters.to_json

    expect(last_response.status).to be 200
    expect(List.count).to eql(num_lists + 1)
    expect(JSON.parse(last_response.body)['fingerprint']).to eql(list.fingerprint)
  end

  it "doesn't show a list without authentication" do
    list = create(:list)

    get "lists/#{list.id}.json"

    expect(last_response.status).to be 401
    expect(last_response.body).to eql("Not authenticated")
  end

  it "doesn't show a list authorized as unassociated account" do
    list = create(:list)
    subscription = create(:subscription, admin: true)
    account = create(:account, email: subscription.email)
    authorize!(account.email, account.set_new_password!)

    get "lists/#{list.id}.json"

    expect(last_response.status).to be 403
    expect(last_response.body).to eql("Not authorized")
  end

  it "doesn't show a list authorized as subscriber" do
    list = create(:list)
    subscription = create(:subscription, list_id: list.id, admin: false)
    account = create(:account, email: subscription.email)
    authorize!(account.email, account.set_new_password!)

    get "lists/#{list.id}.json"

    expect(last_response.status).to be 200
    expect(JSON.parse(last_response.body)['email']).to eq list.email
  end

  it "does show a list authorized as list-admin" do
    list = create(:list)
    subscription = create(:subscription, list_id: list.id, admin: true)
    account = create(:account, email: subscription.email)
    authorize!(account.email, account.set_new_password!)

    get "lists/#{list.id}.json"

    expect(last_response.status).to be 200
    expect(JSON.parse(last_response.body)['email']).to eq list.email
  end

  it 'does show a list authorized as api_superadmin' do
    list = create(:list)
    authorize_as_api_superadmin!

    get "lists/#{list.id}.json"

    expect(last_response.status).to be 200
    expect(JSON.parse(last_response.body)['email']).to eq list.email
  end

  it 'correctly finds a list by email-address that starts with a number' do
    authorize_as_api_superadmin!
    list = create(:list, email: "9list@hostname")
    get "lists/#{list.email}.json"
    expect(last_response.status).to be 200
    expect(JSON.parse(last_response.body)['email']).to eq list.email
  end

end
