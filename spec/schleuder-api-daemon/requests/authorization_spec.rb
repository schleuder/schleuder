require 'helpers/api_daemon_spec_helper'

describe 'authorization via api' do
  it 'allows un-authorized access to /status.json' do
    get '/status.json'
    expect(last_response).to be_ok
  end

  it 'blocks un-authorized access to other URLs' do
    get '/lists.json'
    expect(last_response.status).to be(401)
  end

  it 'allows authorized access' do
    authorize!
    get '/status.json'
    expect(last_response).to be_ok
  end
end
