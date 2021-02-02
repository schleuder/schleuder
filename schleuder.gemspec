# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)
require 'schleuder/version'

Gem::Specification.new do |s|
  s.name         = "schleuder"
  s.version      = Schleuder::VERSION
  s.authors      = 'schleuder dev team'
  s.email        = "team@schleuder.org"
  s.homepage     = "https://schleuder.org/"
  s.summary      = "Schleuder is a gpg-enabled mailing list manager with remailing-capabilities."
  s.description  = "Schleuder is a group's email-gateway: subscribers can exchange encrypted emails among themselves, receive emails from non-subscribers and send emails to non-subscribers via the list.\n\n(Please note: For some platforms there's a better way of installing Schleuder than `gem install`. See <https://schleuder.org/schleuder/docs/server-admins.html#installation> for details.)"
  s.files        = `git ls-files lib locales etc db README.md Rakefile bin/pinentry-clearpassphrase`.split
  s.executables =  %w[schleuder schleuder-api-daemon]
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  # TODO: extend/replace expired cert
  #s.signing_key = "#{ENV['HOME']}/.gem/schleuder-gem-private_key.pem"
  #s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'GPL-3.0'
  s.metadata = {
    "homepage_uri"      => "https://schleuder.org/",
    "documentation_uri" => "https://schleuder.org/docs/",
    "changelog_uri"     => "https://0xacab.org/schleuder/schleuder/blob/master/CHANGELOG.md",
    "source_code_uri"   => "https://0xacab.org/schleuder/schleuder/",
    "bug_tracker_uri"   => "https://0xacab.org/schleuder/schleuder/issues",
    "mailing_list_uri"  => "https://lists.nadir.org/mailman/listinfo/schleuder-announce/",
  }
  s.required_ruby_version = ">= 2.1.0"
  # Explicitly depend on BigDecimal 1.4, because later versions are
  # incompatible with activesupport 4.2, which is a dependency of activerecord 4.2.
  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7.0')
    s.add_runtime_dependency 'bigdecimal', '~> 1.4'
  end
  s.add_runtime_dependency 'gpgme', '~> 2.0', '>= 2.0.19' # Explicitly include to force a version.
  s.add_runtime_dependency 'mail', '~> 2.7.1'
  s.add_runtime_dependency 'mail-gpg', '~> 0.3', '< 0.4.3'
  s.add_runtime_dependency 'activerecord', '~> 4.2'
  # TODO: Drop this once we cease to support ruby 2.1, see #310
  s.add_runtime_dependency 'rack-test', '~> 0.7.0'
  s.add_runtime_dependency 'rake', '>= 10.5.0'
  s.add_runtime_dependency 'sqlite3', '~> 1.3.6'
  s.add_runtime_dependency 'sinatra', '~> 1'
  s.add_runtime_dependency 'sinatra-contrib', '~> 1'
  s.add_runtime_dependency 'thor', '~> 0'
  s.add_runtime_dependency 'thin', '~> 1'
  s.add_runtime_dependency 'charlock_holmes', '~> 0.7.6'
  s.add_development_dependency 'rspec', '~> 3.5.0'
  s.add_development_dependency 'hirb'
  s.add_development_dependency 'factory_bot'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'simplecov-console'
  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.6.0')
    s.add_development_dependency 'irb'
  end
  s.post_install_message = "

    Please consider additionally installing schleuder-cli (allows to
    configure lists from the command line).

    To set up Schleuder on this system please run `schleuder install`.

  "
end
