module Schleuder
  module RequestPlugins
    def self.get_version(arguments, list, mail)
      Schleuder::VERSION
    end
  end
end
