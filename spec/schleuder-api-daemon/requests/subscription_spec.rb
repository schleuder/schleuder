require 'helpers/api_daemon_spec_helper'

describe 'subscription via api' do

  before :each do
    @list = List.last || create(:list)
    @email = create(:subscription).email
  end

  it 'doesn\'t subscribe new member without authorization' do
    parameters = {'list_id' => @list.id, :email => @email}
    expect {
      post '/subscriptions.json', parameters.to_json
      expect(last_response.status).to be 401
    }.to change { Subscription.count }.by 0
  end

  it 'subscribes new member to a list' do
    authorize!
    parameters = {'list_id' => @list.id, :email => @email}
    expect {
      post '/subscriptions.json', parameters.to_json
      expect(last_response.status).to be 201
    }.to change { Subscription.count }.by 1
    expect(Subscription.where(:email => @email).first.admin?).to be false
    expect(Subscription.where(:email => @email).first.delivery_enabled).to be true
  end

  it 'subscribes an admin user' do
    authorize!
    parameters = {'list_id' => @list.id, :email => @email, :admin => true}
    expect {
      post '/subscriptions.json', parameters.to_json
      expect(last_response.status).to be 201
    }.to change { Subscription.count }.by 1
    expect(Subscription.where(:email => @email).first.admin?).to be true
  end

  it 'subscribes an admin user with a truthy value' do
    authorize!
    parameters = {'list_id' => @list.id, :email => @email, :admin => '1'}
    expect {
      post '/subscriptions.json', parameters.to_json
      expect(last_response.status).to be 201
    }.to change { Subscription.count }.by 1
    expect(Subscription.where(:email => @email).first.admin?).to be true
  end

  it 'subscribes an user and unsets delivery flag' do
    authorize!
    parameters = {'list_id' => @list.id, :email => @email, :delivery_enabled => false}
    expect {
      post '/subscriptions.json', parameters.to_json
      expect(last_response.status).to be 201
    }.to change { Subscription.count }.by 1
    expect(Subscription.where(:email => @email).first.delivery_enabled).to be false
  end

  it 'unsubscribes members' do
    authorize!
    subscription = create(:subscription, :list_id => @list.id)
    parameters = {'list_id' => @list.id, :email => @email, :delivery_enabled => false}
    expect {
      delete "/subscriptions/#{subscription.id}.json"
      expect(last_response.status).to be 200
    }.to change { Subscription.count }.by -1
  end
end
