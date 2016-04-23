module Schleuder
  class Conf
    include Singleton

    def config
      @config ||= self.class.load_config('schleuder', ENV['SCHLEUDER_CONFIG'])
    end

    def self.load_config(defaults_basename, filename)
      load_defaults(defaults_basename).deep_merge(load_config_file(filename))
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

    private

    def self.load_config_file(filename)
      file = Pathname.new(filename)
      if file.readable?
        YAML.load(file.read)
      else
        {}
      end
    end

    def self.load_defaults(basename)
      file = Pathname.new(ENV['SCHLEUDER_ROOT']).join("etc/#{basename}.yml")
      if ! file.readable?
        raise RuntimError, "Error: '#{file}' is not a readable file."
      end
      load_config_file(file)
    end
  end
end
