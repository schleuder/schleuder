module Schleuder
  module Errors
    class ReadingConfigFailed < Base
      def initialize(filename)
        @filename = filename
      end

      def message
        t('.errors.reading_config_failed', filename: @filename)
      end
    end
  end
end
