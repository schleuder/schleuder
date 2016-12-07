module Schleuder
  class Cert < Thor
    extend SubcommandFix

    desc 'generate', 'Generate a new TLS-certificate.'
    def generate
      key = Conf.api['tls_key_file']
      cert = Conf.api['tls_cert_file']
      fingerprint = SchleuderCertManager.generate('schleuder', key, cert)
      puts "Fingerprint of generated certificate: #{fingerprint}"
      puts "Have this fingerprint included into the configuration-file of all clients that want to connect to your Schleuder API."
      puts "To activate TLS set `use_tls: true` in #{ENV['SCHLEUDER_CONFIG']} and restart schleuder-api-daemon."
    end

    desc 'fingerprint', 'Show fingerprint of configured certificate.'
    def fingerprint
      cert = Conf.api['tls_cert_file']
      fingerprint = SchleuderCertManager.fingerprint(cert)
      say "Fingerprint of #{Conf.api['tls_cert_file']}: #{fingerprint}"
    end
  end
end
