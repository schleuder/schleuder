module Schleuder
  class Subscription < ActiveRecord::Base
    belongs_to :list

    validates :list_id, inclusion: {
                          in: -> (id) { List.pluck(:id) },
                          message: "must refer to an existing list"
                        }
    validates :email, presence: true, email: true
    validates :fingerprint, allow_blank: true, fingerprint: true
    validates :delivery_enabled, :admin, boolean: true

    default_scope { order(:email) }

    def to_s
      email
    end

    def self.configurable_attributes
      [:fingerprint, :admin, :delivery_enabled]
    end

    def fingerprint=(arg)
      # Strip whitespace from incoming arg.
      write_attribute(:fingerprint, arg.to_s.gsub(/\s*/, '').chomp)
    end

    def key
      # TODO: make key-related methods a concern, so we don't have to go
      # through the list and neither re-implement the methods here.
      # Prefix '0x' to force GnuPG to match only hex-values, not UIDs.
      list.keys("0x#{self.fingerprint}").first
    end

    def send_mail(mail)
      list.logger.debug "Preparing sending to #{self.inspect}"

      if ! self.delivery_enabled
        list.logger.info "Not sending to #{self.email}: delivery is disabled."
        return false
      end

      mail = ensure_headers(mail)
      gpg_opts = self.list.gpg_sign_options

      if self.key.blank?
        if self.list.send_encrypted_only?
          notify_of_missed_message(:absent)
          return false
        else
          list.logger.warn "Sending plaintext because no key is present!"
        end
      elsif ! self.key.usable?
        if self.list.send_encrypted_only?
          notify_of_missed_message(key.usability_issue)
          return false
        else
          list.logger.warn "Sending plaintext because assigned key is #{key.usability_issue}!"
        end
      else
        gpg_opts.merge!(encrypt: true, keys: {self.email => "0x#{self.fingerprint}"})
      end

      list.logger.info "Sending message to #{self.email}"
      mail.gpg gpg_opts
      mail.deliver
    end

    def ensure_headers(mail)
      mail.to = self.email
      mail.from = self.list.email
      mail.return_path = self.list.bounce_address
      mail
    end

    def notify_of_missed_message(reason)
      self.list.logger.warn "Not sending to #{self.email}: key is unusable because it is #{reason} and sending plain text not allowed"
      mail = ensure_headers(Mail.new)
      mail.subject = I18n.t('notice')
      mail.body = I18n.t("missed_message_due_to_unusable_key", list_email: self.list.email) + I18n.t('errors.signoff')
      mail.gpg self.list.gpg_sign_options
      mail.deliver
    end

    def admin?
      self.admin == true
    end

    def delete_key
      list.delete_key(self.fingerprint)
    end

  end
end
