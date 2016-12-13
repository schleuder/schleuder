require 'gem2deb/rake/spectask'

task :setup do
  ENV['SCHLEUDER_ENV'] = 'test'
  ENV['SCHLEUDER_CONFIG'] = 'spec/schleuder.yml'
  # Remove database to ensure clean environment
  `rm db/test.sqlite3 >/dev/null 2>&1 || true`
  # Set up database
  `rake -f debian/Rakefile db:create`
  `rake -f debian/Rakefile db:schema:load`
end

task :run_tests do
  Gem2Deb::Rake::RSpecTask.new do |spec|
    spec.pattern = '../spec/schleuder/*_spec.rb'
  end
end

task :default => [:setup, :run_tests]
