module Schleuder
  class ExtractedKeyword
    attr_reader :name
    attr_accessor :arguments

    def initialize(name:, argument_regexps:)
      @name = name
      @argument_regexps = argument_regexps
      @arguments = []
    end

    def consume_arguments(input)
      new_arguments = into_arguments(input)
      args_to_check = @arguments + new_arguments
      result = args_to_check.each_with_index.map do |arg, index|
        if index >= @argument_regexps.size
          false
        else
          match_data = arg.match(@argument_regexps[index])
          if match_data == nil
            # This means that a mandatory argument wasn't met, which is an
            # error.
            # TODO: proper error that explains the wanted arguments.
            raise "Error: Missing mandatory argument to keyword '#{name}'"
          end
          match_data.to_s
        end
      end

      # Return true if there's room for more arguments, false if there isn't.
      # Excessive data beyond the list of possible arguments result in false.
      # Optional argument-regexps result in an empty string if the compared
      # string doesn't match.
      if result.index(false).blank? && result.index('').blank?
        # Only store the new arguments if they matched.
        @arguments += new_arguments
        return true
      else
        return false
      end
    end

    def into_arguments(string)
      string.to_s.strip.downcase.split(/[,;\s]+/)
    end

  end
end
