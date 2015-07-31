module Schleuder
  class List < ActiveRecord::Base

    has_many :subscriptions, dependent: :destroy
    before_destroy :delete_listdir

    serialize :headers_to_meta, JSON
    serialize :bounces_drop_on_headers, JSON
    serialize :keywords_admin_only, JSON
    serialize :keywords_admin_notify, JSON

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
        :include_openpgp_header,
        :forward_all_incoming_to_admins do |record, attrib, value|
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
          if value.to_s !~ /.*/
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

    def self.configurable_attributes
      @configurable_attributes ||= begin
        all = self.validators.map(&:attributes).flatten.uniq.compact.sort
        all - [:email, :fingerprint]
      end
    end

    def logfile
      @logfile ||= File.join(self.listdir, 'list.log')
    end

    def logger
      @logger ||= Listlogger.new(self)
    end

    def to_s
      email
    end

    def admins
      subscriptions.where(admin: true)
    end

    def key(fingerprint=self.fingerprint)
      keys(fingerprint).first
    end

    def keys(identifier='')
      gpg.keys(identifier)
    end

    def import_key(importable)
      gpg.import_key GPGME::Data.new(importable)
    end

    def delete_key(fingerprint)
      gpg.keys(fingerprint).first.delete!
    end

    def export_key(fingerprint=self.fingerprint)
      key = keys(fingerprint).first
      if key.blank?
        return false
      end
      key.armored
    end

    def check_keys
      now = Time.now
      checkdate = now + (60 * 60 * 24 * 14) # two weeks
      unusable = []
      expiring = []

      keys.each do |key|
        expiry = key.subkeys.first.expires
        if expiry && expiry > now && expiry < checkdate
          # key expires in the near future
          expdays = ((exp - now)/86400).to_i
          expiring << [key, expdays]
        end

        if key.trust
          unusable << [key, key.trust]
        end
      end

      text = ''
      expiring.each do |key,days|
        text << I18n.t('key_expires', {
                          days: days,
                          fingerprint: key.fingerprint,
                          email: key.email
                      })
      end

      unusable.each do |key,trust|
        text << I18n.t('key_unusable', {
                          trust: Array(trust).join(', '),
                          fingerprint: key.fingerprint,
                          email: key.email
                      })
      end
      text
    end

    def self.by_recipient(recipient)
      listname = recipient.gsub(/-(sendkey|request|owner|bounce)@/, '@')
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

    def bounce_address
      @bounce_address ||= email.gsub('@', '-bounce@')
    end

    def gpg
      @gpg_ctx ||= begin
       # TODO: figure out why the homedir isn't recognized
        # Set GNUPGHOME when list is created.
        ENV['GNUPGHOME'] = listdir
        GPGME::Ctx.new armor: true
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

    def subscribe(email, fingerprint)
      Subscription.new(
          list_id: self.id,
          email: email,
          fingerprint: fingerprint
        ).save
    end

    def unsubscribe(email, delete_key=false)
      sub = subscriptions.where(email: email).first
      if sub.blank?
        false
      end

      if res = sub.unsubscribe(delete_key)
        true
      else
        res
      end
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

    private

      def delete_listdir
        if err = FileUtils.rm_r(self.listdir, secure: true)
          logger.info "Deleted listdir"
          return true
        else
          logger.error "Error while deleting listdir: #{err}"
          return false
        end
      end
  end
end
