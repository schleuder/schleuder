module Schleuder
  module Errors
    class ActiveModelError < Base
      def initialize(errors)
        @errors = errors
      end

      def message
        @errors.messages.map do |message|
          message.join(' ')
        end.join("\n")
      end
    end
  end
end
