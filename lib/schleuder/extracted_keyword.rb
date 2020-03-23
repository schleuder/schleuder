module Schleuder
  class ExtractedKeyword
    attr_reader :name
    attr_accessor :arguments

    def initialize(name:, arguments_matcher:)
      @name = name
      @arguments_matcher = arguments_matcher
      @arguments = []
    end

    # TODO: Use the extended KeywordHandler directly, eliminate this class.

    def consume_arguments(input)
      new_arguments = into_arguments(input)
      args_to_check = @arguments + new_arguments
      case @arguments_matcher.call(args_to_check)
      when :more
        # TODO: Maybe only ask for more content if the current line was longer than X characters?
        @arguments += new_arguments
        :more
      when :invalid
        :invalid
      when :end
        @arguments += new_arguments
        :end
      end
    end

    def into_arguments(string)
      string.to_s.strip.downcase.split(/[,;\s]+/)
    end

  end
end
