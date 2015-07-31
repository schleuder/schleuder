module Schleuder
  module Errors
    class UnknownListOption < Base
      def initialize(exception)
        @option = exception.attribute
        @config_file = ENV['SCHLEUDER_LIST_DEFAULTS']
      end

      def message
        t('errors.unknown_list_option', option: @option, config_file: @config_file)
      end
    end
  end
end
