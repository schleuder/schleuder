# TODO: check if gpg1 is present or if we need to work around the "gpg-agent now mandatory"-fuckup.
# TODO: logging. log4r?

# Stdlib
require 'fileutils'
require 'singleton'
require 'yaml'
require 'pathname'

# Setup bundler and bundled gems
ENV['BUNDLE_GEMFILE'] ||= File.expand_path("../../Gemfile",
                                             Pathname.new(__FILE__).realpath)
require 'bundler/setup'
Bundler.require
I18n.enforce_available_locales = false

# Setup schleuder
$:.unshift File.dirname(__FILE__)
ENV["SCHLEUDER_ENV"] ||= 'production'

require 'schleuder/conf'
ActiveRecord::Base.establish_connection(Schleuder::Conf.database)
ActiveRecord::Base.logger = Logger.new("#{File.dirname(__FILE__)}/../log/#{ENV["SCHLEUDER_ENV"]}.log")

# Monkeypatches
require 'schleuder/mail/message.rb'
require 'schleuder/gpgme/import_status.rb'
require 'schleuder/gpgme/key.rb'
require 'schleuder/gpgme/sub_key.rb'

# Error-classes
require 'schleuder/errors/list_exists'
require 'schleuder/errors/file_not_found'
require 'schleuder/errors/active_model_error'
require 'schleuder/errors_list'

# The Code[tm]
require 'schleuder/runner'
require 'schleuder/list'
require 'schleuder/subscription'

include Schleuder
