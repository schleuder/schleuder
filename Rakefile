require_relative 'lib/schleuder.rb'

load "active_record/railties/databases.rake"

# Configure ActiveRecord
ActiveRecord::Tasks::DatabaseTasks.tap do |config|
  config.root = File.dirname(__FILE__)
  config.db_dir = 'db'
  config.migrations_paths = ['db/migrate']
  # TODO: Check for SCHLEUDER_ENV being present
  config.env = ENV['SCHLEUDER_ENV']
  config.database_configuration = Schleuder::Conf.databases
end

# ActiveRecord requires this task to be present
Rake::Task.define_task("db:environment")

task :console do
  exec "irb -r #{File.dirname(__FILE__)}/lib/schleuder.rb"
end
