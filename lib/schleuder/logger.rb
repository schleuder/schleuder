module Schleuder
  def logger
    @logger ||= Logger.new
  end
  module_function :logger

  class Logger < Syslog::Logger
    include LoggerNotifications
    def initialize
      # We need some sender-address different from the superadmin-address.
      @from = "#{`whoami`.chomp}@#{`hostname`.chomp}"
      @adminaddresses = Conf.superadmin
      super('Schleuder', Syslog::LOG_MAIL)
    end
  end

end

