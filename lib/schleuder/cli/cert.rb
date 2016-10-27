module Schleuder
  class Cert < Thor
    extend SubcommandFix

    desc 'generate', 'Generate a new TLS-certificate.'
    def generate
      # TODO: test if Conf.tls_key/cert_file are writeable, else give other filenames.
      key = Conf.api['tls_key_file']
      cert = Conf.api['tls_cert_file']
      fingerprint = SchleuderCertGenerator.create('schleuder', key, cert)

      say "Certificate written to: #{cert}"
      say "Private key written to: #{key}"
      say "If you move these files change tls_cert_file and tls_key_file in the configuration file accordingly."

      say "\nFingerprint of certificate: #{fingerprint}"
      say "Have this fingerprint included into the configuration-file of all clients (SchleuderConf, Webschleuder) that want to connect to your instance of schleuderd."
    end

    desc 'fingerprint', 'Show fingerprint of configured certificate.'
    def fingerprint
      cert = Conf.api['tls_cert_file']
      fingerprint = SchleuderCertManager.fingerprint(cert)
      say "Fingerprint of #{Conf.api['tls_cert_file']}: #{fingerprint}"
    end
  end
end
