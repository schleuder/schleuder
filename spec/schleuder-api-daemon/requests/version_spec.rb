require 'helpers/api_daemon_spec_helper'

describe 'version' do
  it 'does not return the current schleuder version if not authorized' do
    get '/version.json'

    expect(last_response.status).to be 401
    expect(last_response.body).not_to eq "{\"version\":\"#{Schleuder::VERSION}\"}"
  end

  it 'returns the current schleuder version if authorized as subscriber' do
    subscription = create(:subscription, admin: false)
    account = create(:account, email: subscription.email)
    authorize!(account.email, account.set_new_password!)

    get '/version.json'

    expect(last_response.status).to be 200
    expect(last_response.body).to eq "{\"version\":\"#{Schleuder::VERSION}\"}"
  end

  # The version is independent from any list, thus we skip the extra test for
  # unassociated admin.

  it 'returns the current schleuder version if authorized as list-admin' do
    subscription = create(:subscription, admin: true)
    account = create(:account, email: subscription.email)
    authorize!(account.email, account.set_new_password!)

    get '/version.json'

    expect(last_response.status).to be 200
    expect(last_response.body).to eq "{\"version\":\"#{Schleuder::VERSION}\"}"
  end

  it 'returns the current schleuder version if authorized as api_superadmin' do
    authorize_as_api_superadmin!

    get '/version.json'

    expect(last_response.status).to be 200
    expect(last_response.body).to eq "{\"version\":\"#{Schleuder::VERSION}\"}"
  end
end
