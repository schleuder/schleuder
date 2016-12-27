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

  config.before(:suite) do
    set_test_gnupg_home
  end

  config.after(:suite) do
    cleanup_gnupg_home
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  def set_test_gnupg_home
    gpghome_upstream = File.join File.dirname(__dir__), "spec", "gnupg"
    gpghome_tmp = "/tmp/schleuder-#{Time.now.to_i}-#{rand(100)}"
    Dir.mkdir(gpghome_tmp)
    ENV["GNUPGHOME"] = gpghome_tmp
    FileUtils.cp_r Dir["#{gpghome_upstream}/{private*,*.gpg,.*migrated}"], gpghome_tmp
  end

  def cleanup_gnupg_home
    Dir.glob("/tmp/schleuder-*").each {|dir| FileUtils.rm_rf(dir) }
    ENV["GNUPGHOME"] = nil
    puts `gpgconf --kill gpg-agent 2>&1`
  end
end
