# TODO: check if gpg1 is present or if we need to work around the "gpg-agent now mandatory"-fuckup.

# Stdlib
require 'fileutils'
require 'singleton'
require 'yaml'
require 'pathname'
require 'syslog/logger'
require 'logger'
require 'open3'

# Require mandatory libs. The database-layer-lib is required below.
require 'mail-gpg'
require 'active_record'

# An extra from mail-gpg
require 'hkp'

# Load schleuder
rootdir = Pathname.new(__FILE__).dirname.dirname.realpath
$:.unshift File.join(rootdir, 'lib')

# Monkeypatches
require 'schleuder/mail/message.rb'
require 'schleuder/gpgme/import_status.rb'
require 'schleuder/gpgme/key.rb'
require 'schleuder/gpgme/sub_key.rb'

# The Code[tm]
require 'schleuder/errors/base'
Dir[rootdir.to_s + "/lib/schleuder/errors/*.rb"].each do |file|
  require file
end
require 'schleuder/errors_list'
require 'schleuder/conf'
require 'schleuder/version'
require 'schleuder/logger_notifications'
require 'schleuder/logger'
require 'schleuder/listlogger'
require 'schleuder/plugins_runner'
require 'schleuder/passphrase'
Dir[rootdir.to_s + "/lib/schleuder/plugins/*.rb"].each do |file|
  require file
end
require 'schleuder/filters_runner'
Dir[rootdir.to_s + "/lib/schleuder/filters/*.rb"].each do |file|
  require file
end
require 'schleuder/runner'
require 'schleuder/list'
require 'schleuder/list_builder'
require 'schleuder/subscription'

# Setup
ENV["SCHLEUDER_CONFIG"] ||= '/etc/schleuder/schleuder.yml'
ENV["SCHLEUDER_ENV"] ||= 'production'
ENV["SCHLEUDER_ROOT"] = rootdir.to_s

# Require lib for database specified in config.
require Schleuder::Conf.database['adapter']

ActiveRecord::Base.establish_connection(Schleuder::Conf.databases[ENV["SCHLEUDER_ENV"]])
ActiveRecord::Base.logger = Schleuder.logger

Mail.defaults { delivery_method :sendmail }

I18n.load_path += Dir[rootdir.to_s + "/locales/*.yml"]
I18n.enforce_available_locales = true
I18n.default_locale = :en

include Schleuder
