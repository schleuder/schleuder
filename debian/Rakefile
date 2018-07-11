load "active_record/railties/databases.rake"

if Dir.exists?('/etc/schleuder')
require 'schleuder'
else
require_relative '../lib/schleuder.rb'
end

# Configure ActiveRecord
ActiveRecord::Tasks::DatabaseTasks.tap do |config|
  config.root = File.dirname(__FILE__)
  config.db_dir = 'db'
  config.migrations_paths = ['db/migrate']
  config.env = ENV['SCHLEUDER_ENV']
  config.database_configuration = Schleuder::Conf.databases
end

# ActiveRecord requires this task to be present
Rake::Task.define_task("db:environment")

namespace :db do
  # A shortcut.
  task init: ['db:create', 'db:schema:load']
end
