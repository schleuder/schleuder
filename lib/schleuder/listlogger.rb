module Schleuder
  class Listlogger < Logger
    def initialize(filename, list)
      super(filename)
      @from = list.email
      @adminaddresses = list.admins.map(&:email)
    end
  end
end
