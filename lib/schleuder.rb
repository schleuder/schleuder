# default to UTF-8 encoding as early as possible for external
# data.
#
# this should ensure we are able to parse most incoming
# plain text mails in different charsets.
Encoding.default_external = Encoding::UTF_8

# Stdlib
require "etc"
require "fileutils"
require "singleton"
require "yaml"
require "pathname"
require "syslog/logger"
require "logger"
require "open3"
require "socket"
require "base64"

# Require mandatory libs. The database-layer-lib is required below.
require "mail"
require "gpgme"
require "active_record"
require "active_support"
require "active_support/core_ext/string"
require "typhoeus"

# Load schleuder
libdir = Pathname.new(__FILE__).dirname.realpath
rootdir = libdir.dirname
$:.unshift libdir

# Monkeypatches
require "schleuder/mail/parts_list"
require "schleuder/mail/message"
require "schleuder/mail/gpg"
require "schleuder/gpgme/import_status"
require "schleuder/gpgme/key"
require "schleuder/gpgme/sub_key"
require "schleuder/gpgme/ctx"
require "schleuder/gpgme/user_id"
require "schleuder/gpgme/key_extractor"

# The Code[tm]
require "schleuder/errors/base"
Dir["#{libdir}/schleuder/errors/*.rb"].each do |file|
  require file
end
# Load schleuder/conf before the other classes, it defines constants!
require "schleuder/conf"
require "schleuder/version"
require "schleuder/http"
require "schleuder/key_fetcher"
require "schleuder/vks_client"
require "schleuder/sks_client"
require "schleuder/logger_notifications"
require "schleuder/logger"
require "schleuder/listlogger"
require "schleuder/keyword_handlers_runner"
require "schleuder/keyword_handlers/base"
Dir["#{libdir}/schleuder/keyword_handlers/*.rb"].each do |file|
  require file
end
require "schleuder/filters_runner"
Dir["#{libdir}/schleuder/validators/*.rb"].each do |file|
  require file
end
require "schleuder/runner"
require "schleuder/list"
require "schleuder/list_builder"
require "schleuder/subscription"
require "schleuder/email_key_importer"
require "schleuder/account"

require "schleuder/authorizer_policies/base_policy"
require "schleuder/authorizer_policies/subscription_policy"
require "schleuder/authorizer_policies/list_policy"
require "schleuder/authorizer_policies/key_policy"
require "schleuder/authorizer"

require 'schleuder/controllers/base_controller'
require 'schleuder/controllers/keys_controller'
require 'schleuder/controllers/lists_controller'
require 'schleuder/controllers/subscriptions_controller'

# Setup
ENV["SCHLEUDER_CONFIG"] ||= "/etc/schleuder/schleuder.yml"
ENV["SCHLEUDER_LIST_DEFAULTS"] ||= "/etc/schleuder/list-defaults.yml"
ENV["SCHLEUDER_ENV"] ||= "production"
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

File.umask(Schleuder::Conf.umask)

include Schleuder
