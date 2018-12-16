require 'helpers/api_daemon_spec_helper'

describe 'subscription via api' do

  before :each do
    @list = List.last || create(:list)
    @email = 'someone@localhost'
  end

  it 'doesn\'t subscribe new member without authentication' do
    parameters = {'list_id' => @list.id, :email => @email}

    expect(@list.subscriptions.size).to be(0)

    post '/subscriptions.json', parameters.to_json

    expect(last_response.status).to be 401
    expect(@list.reload.subscriptions.size).to be(0)
  end

  it 'subscribes new member to a list as api_superadmin' do
    authorize_as_api_superadmin!
    parameters = {'list_id' => @list.id, :email => @email}

    expect(@list.subscriptions.size).to be(0)

    post '/subscriptions.json', parameters.to_json
    @list.reload

    expect(last_response.status).to be 201
    expect(@list.subscriptions.map(&:email)).to eql([@email])
    expect(@list.subscriptions.first.admin?).to be false
    expect(@list.subscriptions.first.delivery_enabled).to be true
  end

  it 'subscribes new member to a list as list-admin' do
    subscription = create(:subscription, list_id: @list.id, admin: true)
    account = create(:account, email: subscription.email)
    authorize!(account.email, account.set_new_password!)
    parameters = {'list_id' => @list.id, :email => @email}

    post '/subscriptions.json', parameters.to_json
    @list.reload

    expect(last_response.status).to be 201
    expect(@list.subscriptions.map(&:email)).to include(@email)
    expect(@list.subscriptions.first.admin?).to be false
    expect(@list.subscriptions.first.delivery_enabled).to be true
  end

  it "doesn't subscribe a new member to a list as subscriber" do
    subscription = create(:subscription, list_id: @list.id, admin: false)
    account = create(:account, email: subscription.email)
    authorize!(account.email, account.set_new_password!)
    parameters = {'list_id' => @list.id, :email => @email}

    expect(@list.subscriptions.size).to be(1)
    @list.reload

    post '/subscriptions.json', parameters.to_json

    expect(last_response.status).to be 403
    expect(@list.reload.subscriptions.size).to be(1)
  end

  it "doesn't subscribe a new member to a list as unassociated account" do
    account = create(:account)
    authorize!(account.email, account.set_new_password!)
    parameters = {'list_id' => @list.id, :email => @email}

    expect(@list.subscriptions.size).to be(0)
    @list.reload

    post '/subscriptions.json', parameters.to_json

    expect(last_response.status).to be 403
    expect(@list.reload.subscriptions.size).to be(0)
  end

  it 'subscribes an admin user as api_superadmin' do
    authorize_as_api_superadmin!
    parameters = {'list_id' => @list.id, :email => @email, :admin => true}

    expect(@list.subscriptions.size).to be(0)

    post '/subscriptions.json', parameters.to_json
    @list.reload

    expect(last_response.status).to be 201
    expect(@list.subscriptions.map(&:email)).to eql([@email])
    expect(@list.subscriptions.first.admin?).to be true
    expect(@list.subscriptions.first.delivery_enabled).to be true
  end

  it 'subscribes an admin user with a truthy value as api_superadmin' do
    authorize_as_api_superadmin!
    parameters = {'list_id' => @list.id, :email => @email, :admin => '1'}

    expect(@list.subscriptions.size).to be(0)

    post '/subscriptions.json', parameters.to_json
    @list.reload

    expect(last_response.status).to be 201
    expect(@list.subscriptions.map(&:email)).to eql([@email])
    expect(@list.subscriptions.first.admin?).to be true
    expect(@list.subscriptions.first.delivery_enabled).to be true
  end

  it 'subscribes an user and unsets delivery flag as api_superadmin' do
    authorize_as_api_superadmin!
    parameters = {'list_id' => @list.id, :email => @email, :delivery_enabled => false}

    expect(@list.subscriptions.size).to be(0)

    post '/subscriptions.json', parameters.to_json
    @list.reload

    expect(last_response.status).to be 201
    expect(@list.subscriptions.map(&:email)).to eql([@email])
    expect(@list.subscriptions.first.admin?).to be false
    expect(@list.subscriptions.first.delivery_enabled).to be false
  end

  it 'unsubscribes members as api_superadmin' do
    subscription = create(:subscription, :list_id => @list.id)
    authorize_as_api_superadmin!

    expect(@list.subscriptions.map(&:email)).to eql([subscription.email])

    delete "/subscriptions/#{subscription.id}.json"

    expect(last_response.status).to be 200
    expect(@list.reload.subscriptions.map(&:email)).to eql([])
  end

  it 'unsubscribes members as list-admin' do
    subscription = create(:subscription, list_id: @list.id, admin: false)
    admin_subscription = create(:subscription, list_id: @list.id, admin: true)
    account = create(:account, email: admin_subscription.email)
    authorize!(account.email, account.set_new_password!)

    expect(@list.subscriptions.map(&:email)).to include(subscription.email)

    delete "/subscriptions/#{subscription.id}.json"

    expect(last_response.status).to be 200
    expect(@list.reload.subscriptions.map(&:email)).to eql([admin_subscription.email])
  end

  it "doesn't unsubscribes members as subscriber" do
    subscription = create(:subscription, list_id: @list.id, admin: false)
    subscription2 = create(:subscription, list_id: @list.id, admin: false)
    account = create(:account, email: subscription2.email)
    authorize!(account.email, account.set_new_password!)

    delete "/subscriptions/#{subscription.id}.json"

    expect(last_response.status).to be 403
    expect(@list.reload.subscriptions.map(&:email)).to include(subscription.email)
  end

  it "doesn't unsubscribes members as unassociated account" do
    subscription = create(:subscription, list_id: @list.id, admin: false)
    subscription2 = create(:subscription, admin: true)
    account = create(:account, email: subscription2.email)
    authorize!(account.email, account.set_new_password!)

    delete "/subscriptions/#{subscription.id}.json"

    expect(last_response.status).to be 403
    expect(@list.reload.subscriptions.map(&:email)).to include(subscription.email)
  end
end
