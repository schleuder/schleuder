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
      string  = string.to_s << append_original_message(original_message)
      super(string)
      notify_admin(string)
    end

    private

    def append_original_message(original_message)
      if original_message
        "\n\nOriginal message:\n\n#{original_message.to_s}"
      else
        ''
      end
    end

    def notify_admin(string)
      Array(adminaddresses).each do |address|
        mail = Mail.new
        mail.from = @from
        mail.to = address
        mail.subject = 'Error'
        mail.body = string.to_s
        mail.deliver
      end
    end
  end
end

