module Schleuder
  module Errors
    class ActiveModelError < Base
      def initialize(errors)
        messages = errors.messages.map do |message|
          message.join(' ')
        end.join("\n")
        super messages
      end
    end
  end
end
