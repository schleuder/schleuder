module Schleuder
  module Errors
    class Unauthorized < Base
      def initialize
        super t("errors.unauthorized")
      end
    end
  end
end

