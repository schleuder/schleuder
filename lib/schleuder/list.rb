module Schleuder
  class List < ActiveRecord::Base

    has_many :subscriptions, dependent: :destroy

    serialize :headers_to_meta, JSON
    serialize :bounces_drop_on_headers, JSON
    serialize :keywords_admin_only, JSON
    serialize :keywords_admin_notify, JSON

    # TODO: validate email to be a valid address
    validates :email, presence: true, uniqueness: true
    validates :fingerprint, presence: true
    # TODO: more validations

    def to_s
      email
    end

    def admins
      subscriptions.where(admin: true)
    end

    def is_admin?(subscription)
      admins.map(&:email).include?(subscription.email)
    end

    def is_subscribed?(subscription)
      subscriptions.map(&:email).include?(subscription.email)
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
      listname = recipient.gsub(/-(sendkey|request)@/, '@')
      where(email: listname).first
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

    def subscribe(email)
      Subscription.create(email: email, list_id: self.id)
    end

    def self.build(listname, adminemail=nil, adminkeypath=nil)
      # TODO: decide if this ErrorsList-concept should be used all over.
      errors = ErrorsList.new

      if self.where(email: listname).present?
        errors << ListExists.new(listname)
        return [errors, nil]
      end

      # TODO: Break if list_dir exists and isn't empty.
      list_dir = listdir(listname)
      if ! File.exists?(list_dir)
        FileUtils.mkdir_p(list_dir)
      end

      # TODO:
      # * keyring.exists? || create
      
      # TODO: get defaults from some file, not from database
      list = List.create(email: listname, fingerprint: 'deadbeeff00')

      if adminemail.present?
        sub = list.subscribe(adminemail)
        if sub.errors.present?
          errors << ActiveModelError.new(sub.errors)
        end
      end

      if adminkeypath.present?
        if ! File.readable?(adminkeypath)
          errors << FileNotFound.new(adminkeypath)
        end
        list.import_key(File.read(adminkeypath))
      end

      [errors.presence, list.presence]
    end

  end
end
