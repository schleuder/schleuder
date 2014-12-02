# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)
require 'schleuder/version'

Gem::Specification.new do |s|
  s.name         = "schleuder"
  s.version      = Schleuder::VERSION
  s.authors      = %w(lunar ng paz)
  s.email        = "schleuder2@nadir.org"
  s.homepage     = "http://schleuder.nadir.org"
  s.summary      = "Schleuder is a group's gateway: a gpg-enabled mailinglist with remailing-capabilities."
  s.description  = "Schleuder is a group's gateway: subscribers can communicate encrypted (and pseudonymously) among themselves, receive emails from non-subscribers and send emails to non-subscribers via the list.\n\nSchleuder takes care of all decryption and encryption, stripping of headers, formatting conversions, etc. Schleuder can also send out its own public key upon request and process administrative commands by email."
  s.files        = `git ls-files lib locales`.split + %w(README.md)
  s.executables =  `git ls-files bin`.split.map {|file| File.basename(file) }
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'
  # TODO: extend/replace expired cert
  #s.signing_key = "#{ENV['HOME']}/.gem/schleuder-gem-private_key.pem"
  #s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'GPL-3'
  s.add_runtime_dependency 'mail-gpg', '~> 0'
  s.add_runtime_dependency 'activerecord', '~> 4.1'
end
