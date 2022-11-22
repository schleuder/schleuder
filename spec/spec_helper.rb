ENV['SCHLEUDER_ENV'] ||= 'test'
ENV['SCHLEUDER_CONFIG'] = 'spec/schleuder.yml'
ENV['SCHLEUDER_LIST_DEFAULTS'] = 'etc/list-defaults.yml'
if ENV['USE_BUNDLER'] != 'false'
  require 'bundler/setup'
  Bundler.setup
end
# We need to do this before requiring any other code
# Check env if we want to run code coverage analysis
if ENV['CHECK_CODE_COVERAGE'] == 'true'
  require 'simplecov'
  require 'simplecov-html'
  SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
  SimpleCov.start do
    add_filter %r{^/vendor/}
    add_filter %r{^/spec/}
  end
end

require 'schleuder'
require 'schleuder/cli'
require 'database_cleaner'
require 'factory_bot'
require 'net/http'
require 'fileutils'
require 'securerandom'

if ENV['USE_BYEBUG'] != 'false'
  require 'byebug'
end

# Forcing a specific timezone and locale because some tests match on dates and strings.
ENV['TZ'] = 'Etc/UTC'
ENV['LANG'] = 'en_US.UTF-8'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.order = :random

  config.include FactoryBot::Syntax::Methods
  config.before(:suite) do
    FactoryBot.find_definitions
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    Typhoeus::Expectation.clear
  end

  config.around(:each) do |example|
    Mail::TestMailer.deliveries.clear
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.after(:each) do |example|
    FileUtils.rm_rf(Dir['spec/gnupg/pubring.gpg~'])
  end

  config.after(:suite) do
    cleanup_gnupg_home
    stop_smtp_daemon
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  Mail.defaults do
    delivery_method :test
  end

  # Block all unstubbed connections
  Typhoeus::Config.block_connection = true

  def cleanup_gnupg_home
    ENV['GNUPGHOME'] = nil
    FileUtils.rm_rf Schleuder::Conf.lists_dir
  end

  def smtp_daemon_outputdir
    File.join(Conf.lists_dir, 'smtp-daemon-output')
  end

  def start_smtp_daemon
    if File.directory?(smtp_daemon_outputdir)
      # Try to kill it, in case it's still around (this occurred on some
      # systems).
      stop_smtp_daemon
    end

    if ! File.directory?(smtp_daemon_outputdir)
      FileUtils.mkdir_p(smtp_daemon_outputdir)
    end
    daemon = File.join('spec', 'smtp-daemon.rb')
    pid = Process.spawn(daemon, '2523', smtp_daemon_outputdir)
    pidfile = File.join(smtp_daemon_outputdir, 'pid')
    IO.write(pidfile, pid)
  end

  def stop_smtp_daemon
    pidfile = File.join(smtp_daemon_outputdir, 'pid')
    if File.exist?(pidfile)
      pid = File.read(pidfile).to_i
      Process.kill(15, pid)
      FileUtils.rm_rf smtp_daemon_outputdir
    end
  end

  def run_schleuder(command, email, message_path)
    `SCHLEUDER_ENV=test SCHLEUDER_CONFIG=spec/schleuder.yml bin/schleuder #{command} #{email} < #{message_path} 2>&1`
  end

  def run_cli(command)
    `SCHLEUDER_ENV=test SCHLEUDER_CONFIG=spec/schleuder.yml bin/schleuder #{command} 2>&1`
  end

  def with_env(env)
    backup = ENV.to_hash
    ENV.replace(env)
    yield
  ensure
    ENV.replace(backup)
  end

  def process_mail(msg, recipient)
    output = nil
    begin
      output = Schleuder::Runner.new.run(msg, recipient)
    rescue SystemExit
    end
    output
  end

  def teardown_list_and_mailer(list)
    FileUtils.rm_rf(list.listdir)
    Mail::TestMailer.deliveries.clear
  end

  def encrypt_string(list, str)
    _, ciphertext, _ = list.gpg.class.gpgcli("--recipient #{list.fingerprint} --encrypt") do |stdin, stdout, stderr|
      stdin.puts str
      # Apparently it differs between ruby-version if we have to close the stream manually.
      stdin.close if ! stdin.closed?
      stdout.readlines
    end
    ciphertext.reject { |line| line.match(/^\[GNUPG:\]/) }.join
  end

  def capture_output
    orig_stdout = $stdout
    $stdout = StringIO.new
    orig_stderr = $stderr
    $stderr = StringIO.new
    exitcode = nil

    begin
      yield
    rescue SystemExit => exc
      exitcode = exc.status
    end

    $stdout.rewind
    output = $stdout.read
    $stderr.rewind
    errors = $stderr.read
    # Cleanup
    $stderr = orig_stderr
    $stdout = orig_stdout

    [output, errors, exitcode]
  end

  def with_tmpfile(content, &blk)
    file = File.new(File.join(Conf.lists_dir, SecureRandom.hex(32)), 'w+')
    begin
      file.write(content)
      file.close
      yield file.path
    ensure
      File.unlink(file)
    end
  end

  def t(key, **kwargs)
    I18n.t(key, **kwargs)
  end
end
