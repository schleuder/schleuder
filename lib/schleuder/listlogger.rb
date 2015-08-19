module Schleuder
  class Listlogger < ::Logger
    include LoggerNotifications
    def initialize(filename, list)
      super(filename, 2, 102400)
      @from = list.email
      @adminaddresses = list.admins.map(&:email)
      @level = ::Logger.const_get(list.log_level.upcase)
    end
  end
end
