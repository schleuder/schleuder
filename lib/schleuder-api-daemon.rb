#!/usr/bin/env ruby

# Make sinatra use production as default-environment
ENV['RACK_ENV'] ||= 'production'

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
require 'schleuder-api-daemon/helpers/schleuder-api-daemon-helper'

%w[tls_cert_file tls_key_file].each do |config_key|
  path = Conf.api[config_key]
  if ! File.readable?(path)
    $stderr.puts "Error: '#{path}' is not a readable file (from #{config_key} in config)."
    exit 1
  end
end

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
  end

  after do
    # Return connection to pool after each request.
    ActiveRecord::Base.connection.close
  end

  error Errors::KeyNotFound do
    status 404
    json({ error:  'Key not found.' })
  end

  error Errors::SubscriptionNotFound do
    status 404
    json({ error: 'Subscription not found.' })
  end

  error Errors::ListNotFound do
    content_type :json
    status 404
    json({ error: 'List not found.' })
  end

  error Errors::Unauthorized do
    status 403
    json({ error: 'Not authorized' })
  end

  error Errors::LastAdminNotDeletable do
    status 403
    json({ error: 'Last admin cannot be unsubscribed' })
  end

  error do
    exc = env['sinatra.error']
    logger.error "Error: #{env['sinatra.error'].message}"
    case exc
    when Errno::EACCES
      server_error(exc.message)
    else
      client_error(exc.to_s)
    end
  end

  error 404 do
    json({ error: 'Not found' })
  end

  error 401 do
    json({ error: 'Not authenticated' })
  end

  error 403 do
    json({ error: 'Not authorized' })
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
