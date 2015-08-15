module Schleuder
  class Conf
    include Singleton

    def config
      return @config if @config

      config_file = ENV['SCHLEUDER_CONFIG'].to_s

      if ! File.readable?(config_file)
        msg = "Error: '#{ENV['SCHLEUDER_CONFIG']}' is not a readable file."
        raise StandardError, msg
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

    def self.databases
      instance.config['database']
    end

    def self.superadmin
      instance.config['superadmin']
    end

    def self.log_level
      instance.config['log_level'] || 'WARN'
    end

    def self.smtp_host
      instance.config['smtp_host'] || 'localhost'
    end

    def self.smtp_port
      instance.config['smtp_port'] || 25
    end

    def self.smtp_helo_domain
      instance.config['smtp_helo_domain'] || 'localhost'
    end
  end
end
