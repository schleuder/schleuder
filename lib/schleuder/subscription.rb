module Schleuder
  class Subscription < ActiveRecord::Base
    belongs_to :list

    validates  :list_id, inclusion: { in: -> (id) { List.pluck(:id) } }
    validates  :email, presence: true

    default_scope { order(:email) }

    def to_s
      email
    end

    def fingerprint=(arg)
      if arg.present?
        # Strip whitespace from incoming arg.
        write_attribute(:fingerprint, arg.gsub(/\s*/, '').chomp)
      end
    end

    def key
      # TODO: make key-related methods a concern, so we don't have to go
      # through the list and neither re-implement the methods here.
      # Prefix '0x' to force GnuPG to match only hex-values, not UIDs.
      list.keys("0x#{self.fingerprint}").first
    end

    def send_mail(mail)
      mail.to = self.email
      # TODO: implement attach_incoming
      gpg_opts = {encrypt: true, sign: true, keys: {self.email => self.fingerprint}}
      # TODO: catch unusable-key-errors
      if self.key.blank?
        if self.list.send_encrypted_only?
          $stderr.puts "Not sending to #{self.email}: no key present and sending plain text not allowed"
          return false
        else
          gpg_opts.merge!(encrypt: false)
        end
      end
      mail.gpg gpg_opts
      mail.deliver
    end

  end
end
