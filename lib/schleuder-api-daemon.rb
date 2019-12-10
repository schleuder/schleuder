#!/usr/bin/env ruby

# Make sinatra use production as default-environment
ENV['RACK_ENV'] ||= 'production'

PUBLIC_ROUTES = []

$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/namespace'
require 'thin'
require 'schleuder'
require 'schleuder-api-daemon/routes/status'
require 'schleuder-api-daemon/routes/version'
require 'schleuder-api-daemon/routes/list'
require 'schleuder-api-daemon/routes/subscription'
require 'schleuder-api-daemon/routes/key'
require 'schleuder-api-daemon/routes/auth_token'
require 'schleuder-api-daemon/helpers/schleuder-api-daemon-helper'

%w[tls_cert_file tls_key_file].each do |config_key|
  path = Conf.api[config_key]
  if ! File.readable?(path)
    $stderr.puts "Error: '#{path}' is not a readable file (from #{config_key} in config)."
    exit 1
  end
end

I18n.load_path += Dir["#{File.expand_path(".")}/locales/*.yml"]
I18n.enforce_available_locales = true
I18n.default_locale = :en

class SchleuderApiDaemon < Sinatra::Base
  helpers SchleuderApiDaemonHelper

  configure do
    set :server, :thin
    set :port, Schleuder::Conf.api['port'] || 4443
    set :bind, Schleuder::Conf.api['host'] || 'localhost'
    set :raise_errors, false
    if settings.development?
      set :logging, Logger::DEBUG
    else
      set :logging, Logger::WARN
    end
  end

  before do
    content_type :json
    authenticate!
    cast_param_values
    set_locale
  end

  after do
    # Return connection to pool after each request.
    ActiveRecord::Base.connection.close
  end

  error Errors::KeyNotFound do
    status 404
    json({ error: 'Key not found.', error_code: :key_not_found })
  end

  error Errors::SubscriptionNotFound do
    status 404
    json({ error: 'Subscription not found.', error_code: :subscription_not_found  })
  end

  error Errors::ListNotFound do
    content_type :json
    status 404
    json({ error: 'List not found.', error_code: :list_not_found })
  end

  error Errors::Unauthorized do
    status 403
    json({ error: 'Not authorized', error_code: :not_authorized })
  end

  error Errors::LastAdminNotDeletable do
    status 403
    json({ error: 'Last admin cannot be unsubscribed', error_code: :last_admin })
  end

  error do
    # TODO: send less errors to client. Currently also "uninitialized constant"-errors etc. are revealed.
    exc = env['sinatra.error']
    logger.error "Error: #{env['sinatra.error'].message}"
    case exc
    when Errno::EACCES
      server_error(exc.message)
    when ActiveRecord
      client_error(exc.to_s)
    else
      server_error("Unexpected error")
    end
  end

  error 404 do
    json({ error: 'Not found', error_code: :not_found })
  end

  error 401 do
    json({ error: 'Not authenticated', error_code: :not_authenticated })
  end

  error 403 do
    json({ error: 'Not authorized', error_code: :not_authorized })
  end

  def self.run!
    super do |server|
      server.ssl = true
      server.ssl_options = {
        :cert_chain_file  => Conf.api['tls_cert_file'],
        :private_key_file => Conf.api['tls_key_file']
      }
    end
  end
end
