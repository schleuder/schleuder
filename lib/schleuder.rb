# TODO: check if gpg1 is present or if we need to work around the "gpg-agent now mandatory"-fuckup.
# TODO: logging. log4r?

# Stdlib
require 'fileutils'
require 'singleton'
require 'yaml'
require 'pathname'
require 'syslog/logger'
require 'logger'

rootdir = Pathname.new(__FILE__).dirname.dirname.realpath

# Setup bundler and bundled gems
ENV['BUNDLE_GEMFILE'] ||= File.join(rootdir, "Gemfile")
require 'bundler/setup'
Bundler.require

# Load schleuder
$:.unshift File.join(rootdir, 'lib')

# Monkeypatches
require 'schleuder/mail/message.rb'
require 'schleuder/gpgme/import_status.rb'
require 'schleuder/gpgme/key.rb'
require 'schleuder/gpgme/sub_key.rb'

# The Code[tm]
require 'schleuder/errors/base'
Dir[rootdir + "lib/schleuder/errors/*.rb"].each do |file|
  require file
end
require 'schleuder/errors_list'
require 'schleuder/conf'
require 'schleuder/version'
require 'schleuder/logger_notifications'
require 'schleuder/logger'
require 'schleuder/listlogger'
Dir[rootdir + "lib/schleuder/plugins/*.rb"].each do |file|
  require file
end
require 'schleuder/runner'
require 'schleuder/list'
require 'schleuder/subscription'


# Setup
ENV["SCHLEUDER_ENV"] ||= 'production'
ENV["SCHLEUDER_ROOT"] = rootdir.to_s


ActiveRecord::Base.establish_connection(Schleuder::Conf.database)
ActiveRecord::Base.logger = Schleuder.logger

I18n.load_path += Dir[rootdir.to_s + "/locales/*.yml"]
I18n.enforce_available_locales = true
I18n.default_locale = :en

include Schleuder
