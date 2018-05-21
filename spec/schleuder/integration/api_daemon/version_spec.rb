require_relative 'api_daemon_spec_helper'

describe 'version' do
  it 'returns the current schleuder version' do
    authorize!
    get '/version.json'

    expect(last_response.status).to be 200
    expect(last_response.body).to eq "{\"version\":\"#{Schleuder::VERSION}\"}"
  end
end
