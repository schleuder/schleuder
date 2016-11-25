module Schleuder
  def logger
    @logger ||= Logger.new
  end
  module_function :logger

  class Logger < Syslog::Logger
    include LoggerNotifications
    def initialize
      if RUBY_VERSION.to_f < 2.1
        super('Schleuder')
      else
        super('Schleuder', Syslog::LOG_MAIL)
      end
      # We need some sender-address different from the superadmin-address.
      @from = "#{`whoami`.chomp}@#{`hostname`.chomp}"
      @adminaddresses = Conf.superadmin
      @level = ::Logger.const_get(Conf.log_level.upcase)
    end
  end

end

