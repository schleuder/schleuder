# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)
require 'schleuder/version'

Gem::Specification.new do |s|
  s.name         = "schleuder"
  s.version      = Schleuder::VERSION
  s.authors      = 'schleuder dev team'
  s.email        = "schleuder@nadir.org"
  s.homepage     = "https://schleuder.nadir.org/"
  s.summary      = "Schleuder is a gpg-enabled mailinglist with remailing-capabilities."
  s.description  = "Schleuder is a group's email-gateway: subscribers can exchange encrypted emails among themselves, receive emails from non-subscribers and send emails to non-subscribers via the list.\n\nSchleuder takes care of all decryption and (re-)encryption, stripping of headers, and more. Schleuder can also send out its own public key upon request and process administrative commands by email."
  s.files        = `git ls-files lib locales etc db README.md Rakefile bin/pinentry-clearpassphrase`.split
  s.executables =  %w[schleuder schleuder-api-daemon]
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'
  # TODO: extend/replace expired cert
  #s.signing_key = "#{ENV['HOME']}/.gem/schleuder-gem-private_key.pem"
  #s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'GPL-3.0'
  s.add_runtime_dependency 'gpgme', '~> 2.0', '>= 2.0.13' # Explicitly include to force a version.
  s.add_runtime_dependency 'mail', '~> 2.6.0'
  s.add_runtime_dependency 'mail-gpg', '~> 0.3.0'
  s.add_runtime_dependency 'activerecord', '~> 4.1'
  s.add_runtime_dependency 'rake', '>= 10.5.0'
  s.add_runtime_dependency 'sqlite3', '~> 1'
  s.add_runtime_dependency 'sinatra', '~> 1'
  s.add_runtime_dependency 'sinatra-contrib', '~> 1'
  s.add_runtime_dependency 'thor', '~> 0'
  s.add_runtime_dependency 'thin', '~> 1'
  s.add_development_dependency 'rspec', '~> 3.5.0'
  s.add_development_dependency 'hirb'
  s.add_development_dependency 'factory_girl'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'simplecov-console'
  s.post_install_message = "

    Please consider additionally installing schleuder-cli (allows to
    configure lists from the command line).

    To set up Schleuder on this system please run `schleuder install`.

  "
end
