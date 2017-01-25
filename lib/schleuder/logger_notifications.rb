module Schleuder
  module LoggerNotifications
    def adminaddresses
      @adminaddresses.presence || Conf.superadmin.presence || 'root@localhost'
    end

    def error(string)
      super(string)
      notify_admin(string)
    end

    def fatal(string, original_message=nil)
      super(string.to_s + append_original_message(original_message))
      notify_admin(string, original_message)
    end

    def notify_admin(string, original_message=nil, subject='Error')
      # Minimize using other classes here, we don't know what caused the error.
      Array(adminaddresses).each do |address, key|
        mail = Mail.new
        mail.from = @from
        mail.to = address
        mail.subject = subject
        msgpart = Mail::Part.new
        msgpart.charset = 'UTF-8'
        msgpart.body = string.to_s
        mail.add_part msgpart
        if original_message
          orig_part = Mail::Part.new
          orig_part.content_type = 'message/rfc822'
          orig_part.content_description = 'The originally incoming message'
          orig_part.body = original_message.to_s
          mail.add_part orig_part
        end
        if @list.present?
          gpg_opts = @list.gpg_sign_options
          if key.present? && key.usable?
            gpg_opts.merge!(encrypt: true, keys: { address => key.fingerprint })
          end
          mail.gpg gpg_opts
        end
        mail.deliver
      end
      true
    end

    private

    def append_original_message(original_message)
      if original_message
        "\n\nOriginal message:\n\n#{original_message.to_s}"
      else
        ''
      end
    end
  end
end

