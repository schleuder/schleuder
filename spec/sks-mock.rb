#!/usr/bin/env ruby

require 'sinatra/base'

class SksMock < Sinatra::Base
  set :environment, :production
  set :port, 9999
  set :bind, '127.0.0.1'

  get '/status' do
    'ok'
  end

  get '/keys/example.asc' do
    File.read('spec/fixtures/expired_key_extended.txt')
  end

  get '/pks/lookup' do
    case params['search']
    when '0x98769E8A1091F36BD88403ECF71A3F8412D83889', 'admin@example.org'
      File.read('spec/fixtures/expired_key_extended.txt')
    when '0x6EE51D78FD0B33DE65CCF69D2104E20E20889F66', 'old@example.org'
      File.read('spec/fixtures/olduid_key_with_newuid.txt')
    else
      404
    end
  end

  # Run this class as application
  run!
end
