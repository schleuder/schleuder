module Schleuder
  module Errors
    class LoadingListSettingsFailed < Base
      def initialize
        config_file = ENV['SCHLEUDER_LIST_DEFAULTS']
        super t('errors.loading_list_settings_failed', config_file: config_file)
      end
    end
  end
end

