module Schleuder
  module Errors
    class ListPropertyMissing < Base
      def initialize(listdir, property)
        @listdir = listdir
        @property = property
      end

      def to_s
        t("errors.list_#{@property}_missing", listdir: @listdir)
      end
    end
  end
end
