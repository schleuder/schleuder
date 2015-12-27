module Schleuder
  module Errors
    class ListPropertyMissing < Base
      def initialize(property)
        @property = property
      end

      def to_s
        t("errors.list_#{property}_missing")
      end
    end
  end
end
