module Schleuder
  class ActiveModelError
    def initialize(errors)
      @errors = errors
    end

    def to_s
      @errors.messages.map do |message|
        message.join(' ')
      end.join("\n")
    end
  end
end
