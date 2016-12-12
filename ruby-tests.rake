require 'gem2deb/rake/spectask'

task :setup do
  ENV['SCHLEUDER_ENV'] = 'test'
  ENV['SCHLEUDER_CONFIG'] = 'spec/schleuder.yml'
  `rake db:create`
  `rake db:schema:load`
end

task :run_tests do
  Gem2Deb::Rake::RSpecTask.new do |spec|
    spec.pattern = '../spec/schleuder/*_spec.rb'
  end
end

task :default => [:setup, :run_tests]
