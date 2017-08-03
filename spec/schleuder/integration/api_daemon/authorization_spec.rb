require_relative 'api_daemon_spec_helper'

describe 'authorization via api' do
  it 'blocks un-authorized access' do
    get '/status.json'
    expect(last_response.status).to be(401)
  end

  it 'allows authorized access' do
    authorize!
    get '/status.json'
    expect(last_response).to be_ok
  end

end