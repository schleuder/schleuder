ENV['SCHLEUDER_ENV'] ||= 'test'
ENV['SCHLEUDER_CONFIG'] = 'spec/schleuder.yml'
require 'bundler/setup'
Bundler.setup
require 'schleuder'
require 'database_cleaner'
require 'factory_girl'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.order = :random

  config.include FactoryGirl::Syntax::Methods
  config.before(:suite) do
    FactoryGirl.find_definitions
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.after(:each) do |example|
    FileUtils.rm_rf(Dir["spec/gnupg/pubring.gpg~"])
  end

  config.after(:suite) do
    cleanup_gnupg_home
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  def cleanup_gnupg_home
    ENV["GNUPGHOME"] = nil
    if gpg_major_version == '2.1'
      Dir.glob("/tmp/schleuder-test/*/*").each do |dir|
        err = `gpgconf --homedir '#{dir}' --kill gpg-agent 2>&1`
        if ! err.empty?
          puts err
        end
      end
    end
  end

  def gpg_major_version
    `gpgconf --version`.split[2].to_s[0..2]
  end

  Mail.defaults do
    delivery_method :test
  end
end
