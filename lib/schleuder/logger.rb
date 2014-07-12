module Schleuder
  def logger
    # TODO: More logging-options (syslog, other path)
    @logger ||= Logger.new(File.join(ENV['SCHLEUDER_ROOT'],
                                     'log',
                                     "#{ENV['SCHLEUDER_ENV']}.log"))
  end
  module_function :logger

  class Logger < ::Logger
    def initialize(filename)
      # TODO: Better from-address
      @from = "#{`whoami`.chomp}@#{`hostname`.chomp}"
      @adminaddresses = Conf.superadmin
      super(filename)
    end

    def adminaddresses
      @adminaddresses.presence || Conf.superadmin.presence || 'root@localhost'
    end

    def error(string)
      super
      notify_admin(string)
    end

    def fatal(string)
      super
      notify_admin(string)
      exit 2
    end

    private

    def notify_admin(string)
      Array(adminaddresses).each do |address|
        mail = Mail.new
        mail.from = @from
        mail.to = address
        mail.subject = 'Error'
        mail.body = string
        mail.deliver
      end
    end
  end
end
