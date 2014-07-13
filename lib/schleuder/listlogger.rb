module Schleuder
  class Listlogger < ::Logger
    include LoggerNotifications
    def initialize(filename, list)
      @from = list.email
      @adminaddresses = list.admins.map(&:email)
      super(filename)
    end
  end
end
