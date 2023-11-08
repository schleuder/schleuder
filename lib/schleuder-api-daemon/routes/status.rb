class SchleuderApiDaemon < Sinatra::Base
  PUBLIC_ROUTES.push '/status.json'
  get '/status.json' do
    json status: :ok
  end
end
