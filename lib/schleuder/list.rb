module Schleuder
  class List < ActiveRecord::Base

    has_many :subscriptions, dependent: :destroy
    before_destroy :delete_listdir

    serialize :headers_to_meta, JSON
    serialize :bounces_drop_on_headers, JSON
    serialize :keywords_admin_only, JSON
    serialize :keywords_admin_notify, JSON

    validates :email, presence: true, uniqueness: true, email: true
    validates :fingerprint, presence: true, fingerprint: true
    validates :send_encrypted_only,
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
        :forward_all_incoming_to_admins, boolean: true
    validates_each :headers_to_meta,
        :keywords_admin_only,
        :keywords_admin_notify do |record, attrib, value|
          value.each do |word|
            if word !~ /\A[a-z_-]+\z/i
              record.errors.add(attrib, I18n.t("errors.invalid_characters"))
            end
          end
        end
    validates_each :bounces_drop_on_headers do |record, attrib, value|
          value.each do |key, val|
            if key.to_s !~ /\A[a-z-]+\z/i || val.to_s !~ /\A[[:graph:]]+\z/i
              record.errors.add(attrib, I18n.t("errors.invalid_characters"))
            end
          end
        end
    validates :subject_prefix,
        :subject_prefix_in,
        :subject_prefix_out,
        no_line_breaks: true
    validates :openpgp_header_preference,
                presence: true,
                inclusion: {
                  in: %w(sign encrypt signencrypt unprotected none),
                }
    validates :max_message_size_kb, :logfiles_to_keep, greater_than_zero: true
    validates :log_level,
              presence: true,
              inclusion: {
                in: %w(debug info warn error),
              }
    validates :language,
              presence: true,
              inclusion: {
                # TODO: find out why we break translations and available_locales if we use I18n.available_locales here.
                in: %w(de en),
              }
    validates :public_footer,
              allow_blank: true,
              format: {
                with: /\A[[:graph:]\s]*\z/i,
              }

    def self.configurable_attributes
      @configurable_attributes ||= begin
        all = self.validators.map(&:attributes).flatten.uniq.compact.sort
        all - [:email, :fingerprint]
      end
    end

    def logfile
      @logfile ||= File.join(Conf.listlogs_dir, self.email.split('@').reverse, 'list.log')
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

    def secret_key
      gpg.keys(self.fingerprint, true).first
    end

    def keys(identifier='')
      gpg.keys(identifier)
    end

    def keys_by_email(address)
      keys("<#{address}>")
    end

    def import_key(importable)
      gpg.keyimport(GPGME::Data.new(importable))
    end

    def delete_key(fingerprint)
      if key = gpg.keys(fingerprint).first
        key.delete!
        true
      else
        false
      end
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
          expdays = ((expiry - now)/86400).to_i
          expiring << [key, expdays]
        end

        if ! key.usable?
          unusable << [key, key.usability_issue]
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

      unusable.each do |key,usability_issue|
        text << I18n.t('key_unusable', {
                          usability_issue: usability_issue,
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
        # TODO: figure out why set it again...
        # Set GNUPGHOME when list is created.
        set_gnupg_home
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

    def gpg_sign_options
      {sign: true, sign_as: self.fingerprint}
    end

    def fingerprint=(arg)
      # Strip whitespace from incoming arg.
      if arg
        write_attribute(:fingerprint, arg.gsub(/\s*/, '').chomp)
      end
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

    def subscribe(email, fingerprint=nil, adminflag=false, deliveryflag=true)
      adminflag ||= false
      deliveryflag ||= true
      sub = Subscription.new(
          list_id: self.id,
          email: email,
          fingerprint: fingerprint,
          admin: adminflag,
          delivery_enabled: deliveryflag
        )
      sub.save
      sub
    end

    def unsubscribe(email, delete_key=false)
      sub = subscriptions.where(email: email).first
      if sub.blank?
        false
      end

      if ! sub.destroy
        return sub
      end

      if delete_key
        sub.delete_key
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
      return false if ! mail.was_validly_signed?
      admins.find do |admin|
        admin.fingerprint == mail.signature.fingerprint
      end.presence || false
    end

    def set_attribute(attrib, value)
      self.send("#{attrib}=", value)
    end

    private

    def set_gnupg_home
      ENV['GNUPGHOME'] = listdir
    end

    def delete_listdir
      if File.exists?(self.listdir)
        FileUtils.rm_rf(self.listdir, secure: true)
        Schleuder.logger.info "Deleted listdir"
      else
        # Don't use list-logger here — if the list-dir isn't present we can't log to it!
        Schleuder.logger.info "Couldn't delete listdir, directory not present"
      end
      true
    rescue => exc
      # Don't use list-logger here — if the list-dir isn't present we can't log to it!
      Schleuder.logger.error "Error while deleting listdir: #{exc}"
      return false
    end
  end
end
