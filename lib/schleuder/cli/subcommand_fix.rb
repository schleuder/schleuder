module Schleuder
  module SubcommandFix

    # Fixing a bug in Thor where the actual subcommand wouldn't show up
    # with some invokations of the help-output.
    def banner(task, namespace = true, subcommand = true)
      "#{basename} #{task.formatted_usage(self, true, subcommand).split(':').join(' ')}"
    end

  end
end
