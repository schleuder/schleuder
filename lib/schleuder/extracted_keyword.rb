module Schleuder
  class ExtractedKeyword
    attr_reader :name
    attr_accessor :arguments

    def initialize(name, arguments, wanted_arguments)
      @name = name
      @arguments = arguments
      @wanted_arguments = wanted_arguments
    end

    # TODO: consume arguments one by one, and if one doesn't match the requirement, return false so the calling code knows that no additional arguments are wanted.
    # TODO: provide method that checks if consumed arguments fulfill the requirements.

    def add_arguments(arguments)
      @arguments += arguments
    end

    def test_arguments
      @arguments.each_with_index.map do |arg, index|
        if @wanted_arguments[index]
          arg.match(@wanted_arguments[index])
        else
          ''
        end
      end
    end

    def all_arguments_met?
      test_arguments.map do |thing|
        thing.to_s.present?
      end.index(false).blank? && @arguments.size == @wanted_arguments.size
    end

    def mandatory_arguments_met?
      test_arguments.index(nil).blank?
    end

    def wants_more?
      if @arguments.size == 0
        true
      else
        test_arguments.last.to_s.present? && @arguments.size < @wanted_arguments.size
      end
    end
  end
end
