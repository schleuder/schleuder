class SchleuderApiDaemon < Sinatra::Base
  get '/version.json' do
    json version: Schleuder::VERSION
  end
end
