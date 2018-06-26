class SchleuderApiDaemon < Sinatra::Base
  get '/status.json' do
    json status: :ok
  end
end
