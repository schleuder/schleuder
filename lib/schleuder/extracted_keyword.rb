module Schleuder
  class ExtractedKeyword
    attr_reader :name
    attr_accessor :argument_string

    def initialize(name, wanted_arguments_regexp)
      @name = name
      @wanted_arguments_regexp = wanted_arguments_regexp
      @argument_string = ''
    end

    def append_if_valid_arguments?(argument_string)
      testable_string = "#{@argument_string} #{argument_string.to_s.strip.downcase}".strip
      if testable_string.match(@wanted_arguments_regexp)
        @argument_string = testable_string
        true
      else
        false
      end
    end

    def arguments_valid?
      !!@argument_string.match(@wanted_arguments_regexp)
    end

    def arguments
      @arguments ||= @argument_string.split(/[;, ]+/)
    end
  end
end
