module Schleuder
  class ErrorsList
    def initialize(error)
      clear
      if error
        @errors << error
      end
    end

    def <<(arg)
      @errors << arg
    end
    alias_method :push, '<<'

    def to_s
      @errors.map(&:to_s).join("\n")
    end

    def clear
      @errors = []
    end

    def empty?
      @errors.empty?
    end
  end
end
