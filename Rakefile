project = 'schleuder'
require_relative "lib/#{project}.rb"

@version = Schleuder::VERSION
@tagname = "#{project}-#{@version}"
@gpguid = 'schleuder@nadir.org'

load "active_record/railties/databases.rake"

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

def edit_and_add_file(filename)
  puts "Please edit #{filename} to refer to version #{@version}"
  if system("gvim -f #{filename}.md")
    `git add #{filename}.md`
  else
    exit 1
  end
end

def move_sign_and_add(file)
  `mv -iv #{file} gems/`
  `cd gems && gpg -u #{@gpguid} -b #{file}`
  `git add gems/#{file}*`
end

task :console do
  exec "irb -r #{File.dirname(__FILE__)}/lib/schleuder.rb"
end

task :publish_gem => :website
task :git_tag => :check_version

desc "Build new version: git-tag and gem-file"
task :new_version => [
    :check_version,
    :edit_readme, :edit_changelog,
    :git_add_version, :update_gemfile_lock,
    :git_commit,
    :gem, :tarball, :git_amend_gems,
    :git_tag
  ] do
end

desc "Edit CHANGELOG.md"
task :edit_changelog do
  edit_and_add_file('CHANGELOG')
end

desc "Edit README"
task :edit_readme do
  edit_and_add_file('README')
end

desc "Make sure the Gemfile.lock is up to date and added to the index"
task :update_gemfile_lock do
  `bundle install`
  `git add Gemfile.lock`
end

desc 'git-tag HEAD as new version'
task :git_tag do
  `git tag -u #{@gpguid} -s -m "Version #{@version}" #{@tagname}`
end

desc "Add changed version to git-index"
task :git_add_version do
  `git add lib/#{project}/version.rb`
end

desc "Commit changes as new version"
task :git_commit do
  `git commit -m "Version #{@version} (README, gems, ...)"`
end

desc "git-amend gem, tarball and signatures to previous commit"
task :git_amend_gems do
  `git add gems && git commit --amend -C HEAD`
end

desc 'Build, sign and commit a gem-file.'
task :gem do
  gemfile = "#{@tagname}.gem"
  `gem build #{project}.gemspec`
  move_sign_and_add(gemfile)
end

desc 'Publish gem-file to rubygems.org'
task :publish_gem do
  puts "Really push #{@tagname}.gem to rubygems.org? [yN]"
  if gets.match(/^y/i)
    puts "Pushing..."
    `gem push #{@tagname}.gem`
  else
    puts "Not pushed."
  end
end

desc 'Build and sign a tarball'
task :tarball do
  tarball = "#{@tagname}.tar.gz"
  `git archive --format tar.gz --prefix "#{@tagname}/" -o #{tarball} master`
  move_sign_and_add(tarball)
end

desc 'Describe manual release-tasks'
task :website do
  puts "Please update the website:
  * Update changelog.
  * Publish release-announcement.
"
end

desc 'Check if version-tag already exists'
task :check_version do
  # Check if Schleuder::VERSION has been updated since last release
  if `git tag`.include?(@tagname)
    $stderr.puts "Warning: Tag '#{@tagname}' already exists. Did you forget to update #{project}/version.rb?"
    $stderr.print "Delete tag to continue? [yN] "
    if $stdin.gets.match(/^y/i)
      `git tag -d #{@tagname}`
    else
      exit 1
    end
  end
end

