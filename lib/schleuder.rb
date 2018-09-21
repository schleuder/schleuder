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
libdir = Pathname.new(__FILE__).dirname.realpath
rootdir = libdir.dirname
$:.unshift libdir

# Monkeypatches
require 'schleuder/mail/parts_list.rb'
require 'schleuder/mail/message.rb'
require 'schleuder/mail/gpg.rb'
require 'schleuder/mail/encrypted_part.rb'
require 'schleuder/gpgme/import_status.rb'
require 'schleuder/gpgme/key.rb'
require 'schleuder/gpgme/sub_key.rb'
require 'schleuder/gpgme/ctx.rb'
require 'schleuder/gpgme/user_id.rb'

# The Code[tm]
require 'schleuder/errors/base'
Dir["#{libdir}/schleuder/errors/*.rb"].each do |file|
  require file
end
# Load schleuder/conf before the other classes, it defines constants!
require 'schleuder/conf'
require 'schleuder/version'
require 'schleuder/logger_notifications'
require 'schleuder/logger'
require 'schleuder/listlogger'
require 'schleuder/plugin_runners/base'
require 'schleuder/plugin_runners/list_plugins_runner'
require 'schleuder/plugin_runners/request_plugins_runner'
Dir["#{libdir}/schleuder/plugins/*.rb"].each do |file|
  require file
end
require 'schleuder/filters_runner'
Dir["#{libdir}/schleuder/validators/*.rb"].each do |file|
  require file
end
require 'schleuder/runner'
require 'schleuder/list'
require 'schleuder/list_builder'
require 'schleuder/subscription'

# Setup
ENV["SCHLEUDER_CONFIG"] ||= '/etc/schleuder/schleuder.yml'
ENV["SCHLEUDER_LIST_DEFAULTS"] ||= '/etc/schleuder/list-defaults.yml'
ENV["SCHLEUDER_ENV"] ||= 'production'
ENV["SCHLEUDER_ROOT"] = rootdir.to_s

GPGME::Ctx.set_gpg_path_from_env
GPGME::Ctx.check_gpg_version

# TODO: Test if database is writable if sqlite.
ActiveRecord::Base.establish_connection(Schleuder::Conf.database)
ActiveRecord::Base.logger = Schleuder.logger

Mail.defaults do
  delivery_method :smtp, Schleuder::Conf.smtp_settings.symbolize_keys
end

I18n.load_path += Dir["#{rootdir}/locales/*.yml"]
I18n.enforce_available_locales = true
I18n.default_locale = :en

File.umask(0027)

include Schleuder
