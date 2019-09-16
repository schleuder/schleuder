module Schleuder
  module LoggerNotifications
    def adminaddresses
      @adminaddresses.presence || superadmin
    end

    def superadmin
      Conf.superadmin.presence
    end

    def error(string)
      super(string)
      notify_admin(string)
    end

    def fatal(string, original_message=nil)
      super(string.to_s + append_original_message(original_message))
      notify_admin(string, original_message)
    end

    def notify_superadmin(message:, original_message: nil, subject: 'Error')
      notify_admin(message, original_message, subject, superadmin)
    end

    def notify_admin(thing, original_message=nil, subject='Error', recipients=nil)
      # Minimize using other classes here, we don't know what caused the error.
      msg_parts = convert_to_msg_parts(thing, original_message)
      recipients ||= adminaddresses
      Array(adminaddresses).each do |address, key|
        mail = Mail.new
        mail.from = @from
        mail.to = address
        mail.subject = subject
        mail[:Errors_To] = superadmin
        mail.sender = superadmin
        msg_parts.each do |msg_part|
          mail.add_part(msg_part)
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

    def convert_to_msg_parts(thing, original_message)
      msg_parts = Mail::Message.all_to_message_part(thing)
      if original_message.present?
        orig_part = Mail::Part.new
        orig_part.content_type = 'message/rfc822'
        orig_part.content_description = 'The originally incoming message'
        orig_part.body = original_message.to_s
        msg_parts << orig_part
      end
      msg_parts
    end

    def append_original_message(original_message)
      if original_message
        "\n\nOriginal message:\n\n#{original_message.to_s}"
      else
        ''
      end
    end
  end
end

