module Schleuder
  module Errors
    class Base < StandardError
      def t(*args)
        I18n.t(*args)
      end

      def to_s
        message + t('errors.signoff')
      end
    end
  end
end
