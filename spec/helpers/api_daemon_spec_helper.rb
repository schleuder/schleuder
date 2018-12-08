ENV['RACK_ENV'] = 'test'

require 'spec_helper'
require 'rack/test'

require 'schleuder-api-daemon'

module RSpecMixin
  include Rack::Test::Methods
  def app() SchleuderApiDaemon end
end

RSpec.configure { |c| c.include RSpecMixin } # For RSpec 2.x and 3.x

def authorize_as_api_superadmin!
  account = create(:account, email: 'api-superadmin@localhost', api_superadmin: true)
  authorize! account.email, account.set_new_password!
end

def authorize!(email, password)
  basic_authorize email, password
end
