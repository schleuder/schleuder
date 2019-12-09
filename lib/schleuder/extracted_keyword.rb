module Schleuder
  class ExtractedKeyword
    attr_reader :name
    attr_accessor :arguments

    def initialize(name, arguments)
      @name = name
      @arguments = arguments
    end
  end
end
