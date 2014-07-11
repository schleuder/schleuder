module Schleuder
  class Conf
    include Singleton

    def config
      return @config if @config

      default = '/etc/schleuder/schleuder.yml'
      config_file = ENV['SCHLEUDER_CONFIG'].presence || default

      if ! File.readable?(config_file)
        # TODO: raise meaningful exception
        raise StandardError, "Not funny!1!"
      end
      @config = YAML.load(File.read(config_file))
    end

    def self.lists_dir
      instance.config['lists_dir']
    end

    def self.plugins_dir
      instance.config['plugins_dir']
    end

    def self.database
      instance.config['database'][ENV['SCHLEUDER_ENV']]
    end

  end
end
