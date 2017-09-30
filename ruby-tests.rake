require 'gem2deb/rake/spectask'

task :setup do
  ENV['SCHLEUDER_ENV'] = 'test'
  ENV['SCHLEUDER_CONFIG'] = 'spec/schleuder.yml'
  # Remove database to ensure clean environment
  `rm db/test.sqlite3 >/dev/null 2>&1 || true`
  # Set up database
  `rake -f debian/Rakefile db:create`
  `rake -f debian/Rakefile db:schema:load`
  # Kill gpg-agent
  `gpgconf --kill gpg-agent`
end

task :run_tests do
  Gem2Deb::Rake::RSpecTask.new do |spec|
    spec.pattern = ['../spec/*/*_spec.rb', '../spec/*/*/*.spec.rb']
  end
end

task :cleanup do
  at_exit {
    # Remove database to make the build reproducible
    `rm db/test.sqlite3 >/dev/null 2>&1 || true`
    `rm /usr/lib/ruby/vendor_ruby/schleuder/db/test.sqlite3 >/dev/null 2>&1 || true`
    # Kill gpg-agent
    `gpgconf --kill gpg-agent`
  }
end

task :default => [:setup, :run_tests, :cleanup]
