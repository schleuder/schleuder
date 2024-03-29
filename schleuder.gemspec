# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)
require 'schleuder/version'

Gem::Specification.new do |s|
  s.name         = 'schleuder'
  s.version      = Schleuder::VERSION
  s.authors      = 'schleuder dev team'
  s.email        = 'team@schleuder.org'
  s.homepage     = 'https://schleuder.org/'
  s.summary      = 'Schleuder is an encrypting mailing list manager with remailing-capabilities.'
  s.description  = "Schleuder is a group's email-gateway: subscribers can exchange encrypted emails among themselves, receive emails from non-subscribers and send emails to non-subscribers via the list.\n\n(Please note: For some platforms there's a better way of installing Schleuder than `gem install`. See <https://schleuder.org/schleuder/docs/server-admins.html#installation> for details.)"
  s.files        = `git ls-files lib locales etc db README.md Rakefile`.split
  s.executables =  %w[schleuder schleuder-api-daemon]
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.license = 'GPL-3.0'
  s.metadata = {
    'homepage_uri'      => 'https://schleuder.org/',
    'documentation_uri' => 'https://schleuder.org/docs/',
    'changelog_uri'     => 'https://0xacab.org/schleuder/schleuder/blob/main/CHANGELOG.md',
    'source_code_uri'   => 'https://0xacab.org/schleuder/schleuder/',
    'bug_tracker_uri'   => 'https://0xacab.org/schleuder/schleuder/issues',
    'mailing_list_uri'  => 'https://lists.nadir.org/mailman/listinfo/schleuder-announce/',
  }
  s.required_ruby_version = '>= 2.5.0'
  s.add_runtime_dependency 'activerecord', '~> 6.1.3'
  s.add_runtime_dependency 'bcrypt', '~> 3.1.2'
  s.add_runtime_dependency 'charlock_holmes', '~> 0.7.6'
  s.add_runtime_dependency 'gpgme', '~> 2.0', '>= 2.0.19' # Explicitly include to force a version.
  s.add_runtime_dependency 'mail', '~> 2.7.1'
  s.add_runtime_dependency 'mail-gpg', '~> 0.3'
  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.1.0')
    s.add_runtime_dependency 'net-smtp', '~> 0.3.1'
  end
  s.add_runtime_dependency 'rake', '>= 10.5.0'
  s.add_runtime_dependency 'sinatra', '~> 2'
  s.add_runtime_dependency 'sinatra-contrib', '~> 2'
  s.add_runtime_dependency 'sqlite3', '~> 1.4.2'
  s.add_runtime_dependency 'thin', '~> 1'
  s.add_runtime_dependency 'thor', '~> 0'
  s.add_development_dependency 'byebug', '~> 10'
  s.add_development_dependency 'database_cleaner', '~> 2.0'
  s.add_development_dependency 'factory_bot', '~> 6.0'
  s.add_development_dependency 'hirb', '~> 0'
  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.6.0')
    s.add_development_dependency 'irb'
  end
  s.add_development_dependency 'rack-test', '~> 1'
  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'rubocop', '~> 1'
  s.add_development_dependency 'simplecov-console', '~> 0'
  s.post_install_message = "

    Please consider additionally installing schleuder-cli (allows to
    configure lists from the command line).

    To set up Schleuder on this system please run `schleuder install`.

  "
end
