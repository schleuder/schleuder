module Schleuder
  class ExtractedKeyword
    attr_reader :name
    attr_accessor :arguments

    def initialize(name:, handler_class:)
      @name = name
      @handler = handler_class.new
    end

    # TODO: Use the extended KeywordHandler directly, eliminate this class.

    def consume_arguments(input)
      new_arguments = into_arguments(input)
      args_to_check = @handler.arguments + new_arguments
      case @handler.validate_arguments(args_to_check)
      when :more
        # TODO: Maybe only ask for more content if the current line was longer than X characters?
        @handler.arguments += new_arguments
        :more
      when :invalid
        :invalid
      when :end
        @handler.arguments += new_arguments
        :end
      end
    end

    def into_arguments(string)
      string.to_s.strip.downcase.split(/[,;\s]+/)
    end

  end
end
