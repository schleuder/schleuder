module Schleuder
  module Errors
    class ListNameWrong < Base
      def to_s
        t(:wrong_listname_keyword_error)
      end
    end
  end
end
