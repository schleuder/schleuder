ENV['SCHLEUDER_ENV'] ||= 'test'
ENV['SCHLEUDER_CONFIG'] = 'spec/schleuder.yml'
ENV["SCHLEUDER_LIST_DEFAULTS"] = "etc/list-defaults.yml"
require 'bundler/setup'
Bundler.setup
# We need to do this before requiring any other code
# Check env if we want to run code coverage analysis
if ENV['CHECK_CODE_COVERAGE'] != 'false'
    require 'simplecov'
    require 'simplecov-console'
    SimpleCov::Formatter::Console.table_options = {max_width: 400}
    SimpleCov.formatter = SimpleCov::Formatter::Console
    SimpleCov.start
end
require 'schleuder'
require 'schleuder/cli'
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
    Mail::TestMailer.deliveries.clear
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
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  Mail.defaults do
    delivery_method :test
  end

  def cleanup_gnupg_home
    ENV["GNUPGHOME"] = nil
    FileUtils.rm_rf Schleuder::Conf.lists_dir
  end

  def smtp_daemon_outputdir
    File.join(Conf.lists_dir, 'smtp-daemon-output')
  end

  def with_sks_mock
    pid = Process.spawn('spec/sks-mock.rb', [:out, :err] => ["/tmp/sks-mock.log", 'w'])
    sleep 1
    yield
    Process.kill 'TERM', pid
    Process.wait pid
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

  def with_tmpfile(content,&blk)
    file = Tempfile.new('temporary-file',Conf.lists_dir)
    begin
      file.write(content)
      file.close
      yield file.path
    ensure
      file.unlink
    end
  end
end
