module Schleuder
  module Errors
    class Base < StandardError
      def t(*args)
        I18n.t(*args)
      end

      def to_s
        super
      end

      def set_default_locale
        I18n.locale = I18n.default_locale
      end
    end
  end
end
