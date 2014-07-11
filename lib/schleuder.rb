# TODO: check if gpg1 is present or if we need to work around the "gpg-agent now mandatory"-fuckup.
# TODO: logging. log4r?

ENV["SCHLEUDER_ENV"] ||= 'production'

$:.unshift File.dirname(__FILE__)

require 'fileutils'
require 'active_record'
require 'mail-gpg'
require 'singleton'
require 'yaml'

require 'schleuder/conf'
ActiveRecord::Base.logger = Logger.new("log/#{ENV["SCHLEUDER_ENV"]}.log")
ActiveRecord::Base.establish_connection(Schleuder::Conf.database)

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

require 'schleuder/runner'
require 'schleuder/list'
require 'schleuder/subscription'

include Schleuder
