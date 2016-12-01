module Schleuder
  class Conf
    include Singleton

    EMAIL_REGEXP = /\A.+@.+\z/i

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

    def self.api
      instance.config['api'] || {}
    end

    def self.api_use_tls?
      api['use_tls'].to_s == 'true'
    end

    def self.api_valid_api_keys
      Array(api['valid_api_keys'])
    end

    # Three legacy options
    def self.smtp_host
      instance.config['smtp_host']
    end

    def self.smtp_port
      instance.config['smtp_port']
    end

    def self.smtp_helo_domain
      instance.config['smtp_helo_domain']
    end

    def self.smtp_settings
      settings = instance.config['smtp_settings'] || {}
      # Support previously used config-options.
      # Remove this in future versions.
      {smtp_host: :address, smtp_port: :port, smtp_helo_domain: :domain}.each do |old, new|
        value = self.send(old)
        if value.present?
          Schleuder.logger.warn "Deprecation warning: In schleuder.yml #{old} should be changed to smtp_settings[#{new}]."
          settings[new] = value
        end
      end
      settings
    end

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
        raise RuntimeError, "Error: '#{file}' is not a readable file."
      end
      load_config_file(file)
    end
  end
end
