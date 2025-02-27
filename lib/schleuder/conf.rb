require 'erb'

module Schleuder
  class Conf
    include Singleton

    EMAIL_REGEXP = URI::MailTo::EMAIL_REGEXP
    # TODO: drop v3 keys and only accept length of 40
    FINGERPRINT_REGEXP = /\A(0x)?[a-f0-9]{32}([a-f0-9]{8})?\z/i

    DEFAULTS = {
      'lists_dir' => '/var/lib/schleuder/lists',
      'umask' => 0077,
      'listlogs_dir' => '/var/lib/schleuder/lists',
      'keyword_handlers_dir' => '/usr/local/lib/schleuder/keyword_handlers',
      'filters_dir' => '/usr/local/lib/schleuder/filters',
      'log_level' => 'warn',
      'superadmin' => 'root@localhost',
      'vks_keyserver' => 'https://keys.openpgp.org',
      'sks_keyserver' => 'http://pool.sks-keyservers.net',
      'http_proxy' => '',
      'smtp_settings' => {
        'address' => 'localhost',
        'port' => 25,
        'domain' => 'localhost',
        'enable_starttls_auto' => true,
        # Don't verify by default because most smtp servers don't include
        # 'localhost' into their TLS-certificates.
        'openssl_verify_mode' => 'none',
        'authentication' => nil,
        'user_name' => nil,
        'password' => nil,
      },
      'database' => {
        'production' => {
          'adapter' =>  'sqlite3',
          'database' => '/var/lib/schleuder/db.sqlite',
          'timeout' => 5000
        }
      },
      'api' => {
        'host' => 'localhost',
        'port' => 4443,
        'tls_cert_file' => '/etc/schleuder/schleuder-certificate.pem',
        'tls_key_file' => '/etc/schleuder/schleuder-private-key.pem',
        'valid_api_keys' => []
      }
    }

    def config
      @config ||= load_config(ENV['SCHLEUDER_CONFIG'])
    end

    def reload!
      @config = nil
      config
    end

    def self.lists_dir
      instance.config['lists_dir']
    end

    def self.umask
      instance.config['umask']
    end

    def self.listlogs_dir
      instance.config['listlogs_dir']
    end

    def self.keyword_handlers_dir
      instance.config['keyword_handlers_dir']
    end

    def self.filters_dir
      instance.config['filters_dir']
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

    def self.vks_keyserver
      instance.config['vks_keyserver']
    end

    def self.sks_keyserver
      instance.config['sks_keyserver']
    end

    def self.http_proxy
      instance.config['http_proxy']
    end

    private

    def load_config(filename)
      DEFAULTS.deep_merge(load_config_file(filename))
    end

    def load_config_file(filename)
      file = Pathname.new(filename)
      if file.readable?
        YAML.load(ERB.new(file.read).result)
      else
        {}
      end
    end
  end
end
