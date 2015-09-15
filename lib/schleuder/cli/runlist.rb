module Schleuder
  module Cli
    class Runlist < Thor

      default_task :runlist
      # 'run' is a reserved word in Thor, so we need to call the method
      # differently.
      desc 'runlist list@hostname', 'Run a message through a list'
      def runlist(listname)
        message = STDIN.read
        error = Schleuder::Runner.new.run(message, listname)
        if error.kind_of?(StandardError)
          error error
        end
      rescue => exc
        begin
          Schleuder.logger.fatal(exc.message, message)
          say I18n.t('errors.fatalerror')
        rescue => e
          # Give users a clue what to do in case everything blows up.
          # As apparently even the logging raised exceptions we can't even store
          # any information in the logs.
          say "A serious, unhandleable error happened. Please contact the administrators of this system or service and provide them with the following information:\n\n#{e.message}"
        end
        exit 1
      end

    end
  end
end
