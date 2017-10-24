require 'gem2deb/rake/spectask'
require 'securerandom'

task :setup do
  ENV['SCHLEUDER_ENV'] = 'test'
  ENV['SCHLEUDER_CONFIG'] = 'spec/schleuder.yml'

  tmp_dir = File.join('/tmp/', "schleuder-#{SecureRandom.hex}")
  ENV["SCHLEUDER_DB_PATH"] = File.join(tmp_dir, 'test.sqlite3')
  ENV["SCHLEUDER_TMP_DIR"] = tmp_dir

  ENV['USE_BUNDLER'] = 'false'
  ENV['CHECK_CODE_COVERAGE'] = 'false'

  # Set up database
  `rake -f debian/Rakefile db:create`
  `rake -f debian/Rakefile db:schema:load`
end

task :run_tests do
  Gem2Deb::Rake::RSpecTask.new do |spec|
    spec.pattern = ['../spec/*/*_spec.rb', '../spec/*/*/*.spec.rb']
  end
end

task :cleanup do
  at_exit {
    # Remove lists dir to make the build reproducible
    `rm #{ENV["SCHLEUDER_TMP_DIR"]} >/dev/null 2>&1 || true`
  }
end

task :default => [:setup, :run_tests, :cleanup]
