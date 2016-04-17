module Schleuder
  class Conf
    include Singleton

    def config
      return @config if @config

      config_file = ENV['SCHLEUDER_CONFIG'].to_s
      gem_config_file = ENV['SCHLEUDER_GEM_CONFIG'].to_s
      unless File.readable?(gem_config_file) || File.readable?(config_file)
        error("None of the config files is readable: #{gem_config_file}, #{config_file}"
      end

      @config = if File.readable?(config_file)
        YAML.load_file(config_file)
      else
        {}
      end

      if File.readable?(gem_config_file)
        @config.merge!(YAML.load_file(gem_config_file))
      end

      @config
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
    private
    def error(msg)
      raise StandardError, "Error: #{msg}"
    end
  end
end
