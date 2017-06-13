ENV['RACK_ENV'] = 'test'

require 'spec_helper'
require 'rack/test'

require 'schleuder-api-daemon'

module RSpecMixin
  include Rack::Test::Methods
  def app() SchleuderApiDaemon end
end

RSpec.configure { |c| c.include RSpecMixin } # For RSpec 2.x and 3.x

def authorize!
  basic_authorize 'schleuder', 'test_api_key'
end
