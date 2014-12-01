require_relative 'lib/schleuder.rb'

load "active_record/railties/databases.rake"

# Configure ActiveRecord
ActiveRecord::Tasks::DatabaseTasks.tap do |config|
  config.root = File.dirname(__FILE__)
  config.db_dir = 'db'
  config.migrations_paths = ['db/migrate']
  # TODO: Check for settings being available in config file.
  config.env = ENV['SCHLEUDER_ENV']
  config.database_configuration = YAML.load(File.read(ENV['SCHLEUDER_CONFIG']))['database']
end

# ActiveRecord requires this task to be present
Rake::Task.define_task("db:environment")

task :console do
  exec "irb -r #{File.dirname(__FILE__)}/lib/schleuder.rb"
end
