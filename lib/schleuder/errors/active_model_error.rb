module Schleuder
  class ActiveModelError
    def initialize(errors)
      @errors = errors
    end

    def to_s
      @errors.map do |error|
        error.join(' ')
      end.join("\n")
    end
  end
end
