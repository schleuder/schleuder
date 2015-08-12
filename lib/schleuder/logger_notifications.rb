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
      Array(adminaddresses).each do |address|
        mail = Mail.new
        mail.from = @from
        mail.to = address
        mail.subject = subject
        msgpart = Mail::Part.new
        msgpart.body = string.to_s
        mail.add_part msgpart
        if original_message
          mail.add_part Mail::Part.new(original_message)
          mail.parts.last.content_description = 'The originally incoming message'
        end
        mail.deliver
      end
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

