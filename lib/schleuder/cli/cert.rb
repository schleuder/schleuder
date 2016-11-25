module Schleuder
  class Cert < Thor
    extend SubcommandFix

    desc 'generate', 'Generate a new TLS-certificate.'
    def generate
      key = Conf.api['tls_key_file']
      cert = Conf.api['tls_cert_file']
      SchleuderCertManager.generate('schleuder', key, cert)
    end

    desc 'fingerprint', 'Show fingerprint of configured certificate.'
    def fingerprint
      cert = Conf.api['tls_cert_file']
      fingerprint = SchleuderCertManager.fingerprint(cert)
      say "Fingerprint of #{Conf.api['tls_cert_file']}: #{fingerprint}"
    end
  end
end
