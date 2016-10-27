require 'openssl'
require 'pathname'

class SchleuderCertManager
  def self.generate(project_name, filename_key, filename_cert)
    keysize = 2048
    subject = "/C=MW/O=Schleuder/OU=#{project_name}"
    filename_key = Pathname.new(filename_key).expand_path
    filename_cert = Pathname.new(filename_cert).expand_path

    key = OpenSSL::PKey::RSA.new(keysize)
    cert = OpenSSL::X509::Certificate.new
    cert.subject = OpenSSL::X509::Name.parse(subject)
    cert.issuer = cert.subject
    cert.not_before = Time.now
    cert.not_after = Time.now + 10 * 365 * 24 * 60 * 60
    cert.public_key = key.public_key
    cert.serial = 0x0
    cert.version = 2

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = cert
    cert.extensions = [
      ef.create_extension("basicConstraints","CA:TRUE", true),
      ef.create_extension("subjectKeyIdentifier", "hash"),
    ]
    cert.add_extension ef.create_extension("authorityKeyIdentifier",
                                           "keyid:always,issuer:always")

    cert.sign key, OpenSSL::Digest::SHA256.new

    [filename_key, filename_cert].each do |filename|
      if filename.exist?
        error "File exists: #{filename} — (re)move it or change configuration file to proceed."
      end
      if ! filename.dirname.exist?
        filename.dirname.mkpath
      end
    end

    filename_key.open('w', 400) do |fd|
      fd.puts key
    end

    filename_cert.open('w') do |fd|
      fd.puts cert.to_pem
    end

    fingerprint(cert)
  rescue => exc
    error exc.message
  end

  def self.fingerprint(cert)
    if ! cert.is_a?(OpenSSL::X509::Certificate)
      path = Pathname.new(cert).expand_path
      if ! path.readable?
        error "Error: Not a readable file: #{path}"
      end
      cert = OpenSSL::X509::Certificate.new(path.read)
    end
    OpenSSL::Digest::SHA256.new(cert.to_der).to_s
  end

  def self.error(msg)
    $stderr.puts "Error: #{msg}"
    exit 1
  end
end
