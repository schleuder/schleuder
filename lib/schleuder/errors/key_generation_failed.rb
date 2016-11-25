module Schleuder
  module Errors
    class KeyGenerationFailed < Base
      def initialize(listdir, listname)
        @listdir = listdir
        @listname = listname
      end

      def message
        t('errors.key_generation_failed',
          { listdir: @listdir,
            listname: @listname })
      end
    end
  end
end
