module Schleuder
  module Errors
    class ResourceNotFound < Base
      def initialize
        super "Resource not found!"
      end
    end
  end
end

