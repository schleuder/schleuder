module Schleuder
  module Errors
    class FileNotFound < Base
      def initialize(file)
        @file = file
      end

      def message
        t('errors.file_not_found', file: @file)
      end
    end
  end
end

