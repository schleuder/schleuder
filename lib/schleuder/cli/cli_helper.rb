module Schleuder
  module CliHelper
    def self.included(base)
      base.no_commands do
        def fatal(msg, exitcode = 1)
          error("Error: #{msg}" + t('errors.signoff'))
          exit exitcode
        end
      end
    end
  end
end
