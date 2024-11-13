module Schleuder
  def logger
    @logger ||= Logger.new
  end
  module_function :logger

  class Logger < Syslog::Logger
    include LoggerNotifications
    def initialize
      super('Schleuder', Syslog::LOG_MAIL)
      # We need some sender-address different from the superadmin-address.
      @from = "#{Etc.getlogin}@#{Addrinfo.getaddrinfo(Socket.gethostname, nil).first.getnameinfo.first}"
      @adminaddresses = Conf.superadmin
      @level = ::Logger.const_get(Conf.log_level.upcase)
    end
  end

end

