module Schleuder
  class List < ActiveRecord::Base

    has_many :subscriptions, dependent: :destroy

    serialize :headers_to_meta, JSON
    serialize :bounces_drop_on_headers, JSON
    serialize :keywords_admin_only, JSON
    serialize :keywords_admin_notify, JSON

    # TODO: validate email to be a valid address
    # TODO: I18n
    validates :email,
              presence: true,
              uniqueness: true,
              format: {
                with: /\A.+@.+\z/i,
                message: 'is not a valid email address'
              }
    validates :fingerprint,
                presence: true,
                format: { with: /\A[a-f0-9]+\z/i }
    validates_each :send_encrypted_only,
        :receive_encrypted_only,
        :receive_signed_only,
        :receive_authenticated_only,
        :receive_from_subscribed_emailaddresses_only,
        :receive_admin_only,
        :keep_msgid,
        :bounces_drop_all,
        :bounces_notify_admins,
        :include_list_headers,
        :include_openpgp_header do |record, attrib, value|
          if ! [true, false].include?(value)
            record.errors.add(attrib, 'must be true or false')
          end
        end
    validates_each :headers_to_meta,
        :keywords_admin_only,
        :keywords_admin_notify do |record, attrib, value|
          value.each do |word|
            if word !~ /\A[a-z_-]+\z/i
              record.errors.add(attrib, 'contains invalid characters')
            end
          end
        end
    validates_each :subject_prefix,
        :subject_prefix_in,
        :subject_prefix_out do |record, attrib, value|
          # Accept everything but newlines
          if value !~ /./
            record.errors.add(attrib, 'must not include line-breaks')
          end
        end
    validates :openpgp_header_preference,
                presence: true,
                inclusion: {
                  in: %w(sign encrypt signencrypt unprotected none),
                  message: 'must be one of: sign, encrypt, signencrypt, unprotected, none'
                }
    validates :max_message_size_kb,
              presence: true,
              format: {
                with: /\A[0-9]+\z/,
                message: 'must be a number'
              }
    validates :log_level,
              presence: true,
              inclusion: {
                in: %w(debug info warn error),
                message: 'must be one of: debug, info, warn, error'
              }
    validates :language,
              presence: true,
              inclusion: {
                # TODO: find out why we break translations and available_locales if we use I18n.available_locales here.
                in: %w(de en),
                message: "must be one of: en, de"
              }

    def logger
      @logger ||= Listlogger.new(File.join(self.listdir, 'list.log'),
                                 self)
    end

    def to_s
      email
    end

    def admins
      subscriptions.where(admin: true)
    end

    def key
      keys(fingerprint).first
    end

    def armored_key
      GPGME::Key.export self.fingerprint, armor: true
    end

    def keys(identifier='.')
      gpg.keys(identifier)
    end

    def import_key(importable)
      GPGME::Key.import importable
    end

    def self.by_recipient(recipient)
      listname = recipient.gsub(/-(sendkey|request|owner)@/, '@')
      where(email: listname).first
    end

    def sendkey_address
      @sendkey_address ||= email.gsub('@', '-sendkey@')
    end

    def request_address
      @request_address ||= email.gsub('@', '-request@')
    end

    def owner_address
      @owner_address ||= email.gsub('@', '-owner@')
    end

    def gpg
      @gpg_ctx ||= begin
       # TODO: figure out why the homedir isn't recognized
        ENV['GNUPGHOME'] = listdir
        setup_gpg_agent if self.gpg_passphrase.present?
        GPGME::Ctx.new
      end
    end

    # TODO: place this somewhere sensible.
    # Call cleanup when script finishes.
    #Signal.trap(0, proc { @list.cleanup })
    def cleanup
      if @gpg_agent_pid
        Process.kill('TERM', @gpg_agent_pid.to_i)
      end
    rescue => e
      $stderr.puts "Failed to kill gpg-agent: #{e}"
    end

    def fingerprint=(arg)
      # Strip whitespace from incoming arg.
      write_attribute(:fingerprint, arg.gsub(/\s*/, '').chomp)
    end

    def self.listdir(listname)
      File.join(
          Conf.lists_dir,
          listname.split('@').reverse
        )
    end

    def listdir
      @listdir ||= self.class.listdir(self.email)
    end

    def setup_gpg_agent
      # TODO: move this to gpgme/mail-gpg
      require 'open3'
      ENV['GPG_AGENT_INFO'] = `eval $(gpg-agent --allow-preset-passphrase --daemon) && echo $GPG_AGENT_INFO`
      @gpg_agent_pid = ENV['GPG_AGENT_INFO'].split(':')[1]
      `gpgconf --list-dir`.match(/libexecdir:(.*)/)
      gppbin = File.join($1, 'gpg-preset-passphrase')
      Open3.popen3(gppbin, '--preset', self.fingerprint) do |stdin, stdout, stderr|
        stdin.puts self.gpg_passphrase
      end
    end

    def subscribe(email, fingerprint)
      Subscription.create(list_id: self.id, email: email, fingerprint: fingerprint)
    end

    def keywords_admin_notify
      Array(read_attribute(:keywords_admin_notify))
    end

    def keywords_admin_only
      Array(read_attribute(:keywords_admin_only))
    end

    def admin_only?(keyword)
      keywords_admin_only.include?(keyword)
    end

    def from_admin?(mail)
      return false if ! mail.validly_signed?
      admins.find do |admin|
        admin.fingerprint == mail.signature.fingerprint
      end.presence || false
    end
  end
end
