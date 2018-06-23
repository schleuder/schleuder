ENV['RACK_ENV'] = 'test'

require 'spec_helper'
require 'rack/test'

require 'schleuder-api-daemon'

module RSpecMixin
  include Rack::Test::Methods
  def app() SchleuderApiDaemon end
end

RSpec.configure do |config|
  config.include RSpecMixin # For RSpec 2.x and 3.x

  config.before(:each) do
    @account = create(:account, email: 'api-superadmin@localhost', api_superadmin: true)
    @account_password = @account.set_new_password!
  end
end

def authorize!
  basic_authorize @account.email, @account_password
end
