# TODO: check if gpg1 is present or if we need to work around the "gpg-agent now mandatory"-fuckup.
# TODO: logging. log4r?

ENV["SCHLEUDER_ENV"] ||= 'production'

$:.unshift File.dirname(__FILE__)

require 'fileutils'
require 'active_record'
require 'singleton'
require 'yaml'

require 'schleuder/conf'
ActiveRecord::Base.logger = Logger.new("log/#{ENV["SCHLEUDER_ENV"]}.log")
ActiveRecord::Base.establish_connection(Schleuder::Conf.database)

require 'schleuder/errors_list'
require 'schleuder/errors/list_exists'
require 'schleuder/errors/file_not_found'
require 'schleuder/errors/active_model_error'
require 'schleuder/list'
require 'schleuder/subscription'

