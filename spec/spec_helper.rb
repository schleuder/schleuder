ENV['SCHLEUDER_ENV'] ||= 'test'
ENV['SCHLEUDER_CONFIG'] = 'spec/schleuder.yml'
ENV["SCHLEUDER_LIST_DEFAULTS"] = "etc/list-defaults.yml"
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
    DatabaseCleaner.strategy = :deletion
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
    stop_smtp_daemon
    delete_smtp_daemon_outputdir
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  def cleanup_gnupg_home
    ENV["GNUPGHOME"] = nil
    FileUtils.rm_rf Schleuder::Conf.lists_dir
  end

  def smtp_daemon_outputdir
    File.join(Conf.lists_dir, 'smtp-daemon-output')
  end

  def start_smtp_daemon
    if ! File.directory?(smtp_daemon_outputdir)
      FileUtils.mkdir_p(smtp_daemon_outputdir)
    else
      # Try to kill it, in case it's still around (this occurred on some
      # systems).
      stop_smtp_daemon(9)
    end
    daemon = File.join('spec', 'smtp-daemon.rb')
    pid = Process.spawn(daemon, '2523', smtp_daemon_outputdir)
    pidfile = File.join(smtp_daemon_outputdir, 'pid')
    IO.write(pidfile, pid)
  end

  def stop_smtp_daemon(signal=15)
    pidfile = File.join(smtp_daemon_outputdir, 'pid')
    if File.exist?(pidfile)
      pid = File.read(pidfile).to_i
      Process.kill(signal, pid)
    end
  end

  def delete_smtp_daemon_outputdir
    FileUtils.rm_rf smtp_daemon_outputdir
  end

  def run_schleuder(command, email, message_path)
    `SCHLEUDER_ENV=test SCHLEUDER_CONFIG=spec/schleuder.yml bin/schleuder #{command} #{email} < #{message_path} 2>&1`
  end

  def run_cli(command)
    `SCHLEUDER_ENV=test SCHLEUDER_CONFIG=spec/schleuder.yml bin/schleuder #{command} 2>&1`
  end

  Mail.defaults do
    delivery_method :test
  end
end
