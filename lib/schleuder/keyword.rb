module Schleuder
  class Keyword
    attr_reader :name
    attr_accessor :arguments

    def initialize(name, arguments)
      @name = name
      @arguments = arguments
    end

    def valid_arguments?
    end
  end
end
