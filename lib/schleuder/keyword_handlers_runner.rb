module Schleuder
  class KeywordHandlersRunner
    REGISTERED_KEYWORDS = {list: {}, request: {}}
    RESERVED_KEYWORDS = %w[list-name]

    class << self
      def register_keyword(type:, keyword:, handler_class:)
        assert_valid_input!(type: type, keyword: keyword, handler_class: handler_class)
        REGISTERED_KEYWORDS[type.to_sym][keyword.to_s.dasherize] = handler_class
      end

      def known_keywords(type)
        REGISTERED_KEYWORDS[type.to_sym]
      end

      def run(type:, list:, mail:)
        list.logger.debug "Starting #{self}"
        assert_valid_type!(type)

        # TODO: raise exceptions, not return errors, in order to make this work for list-keywords.
        error = check_mandatory_keywords(mail)
        return [error] if error.present?

        output = mail.keywords.map do |extracted_keyword|
          if ! is_reserved_keyword?(extracted_keyword)
            run_handler(mail, list, type, extracted_keyword)
          end
        end

        output.flatten.compact
      end


      private


      def check_unknown_keywords(mail, type)
        given_keywords = mail.keywords.map(&:first)
        unknown_keywords = given_keywords - known_keywords
        if unknown_keywords.present?
          error_messages = unknown_keywords.map do |keyword|
            I18n.t('errors.unknown_keyword', keyword: keyword)
          end
          return error_messages
        end
      end

      def run_handler(mail, list, type, extracted_keyword)
        list.logger.debug "run_handler() with keyword '#{extracted_keyword}'"

        keyword_data = REGISTERED_KEYWORDS[type.to_sym][extracted_keyword.name]
        handler_class = keyword_data[:klass]
        output = handler_class.new(mail: mail, arguments: extracted_keyword.arguments).run

        if list.keywords_admin_notify.include?(extracted_keyword.name)
          notify_admins(type, mail, list, extracted_keyword.name, extracted_keyword.arguments, output)
        end
        return output
      rescue Errors::Unauthorized
        I18n.t('errors.not_permitted_for_subscribers', keyword: extracted_keyword.name)
      rescue Errors::Base => exc
        exc.to_s + t('errors.signoff')
      rescue => exc
        # Log to system, this information is probably more useful for
        # system-admins than for list-admins.
        Schleuder.logger.error(exc.message_with_backtrace)
        I18n.t('keyword_handlers.handler_failed', keyword: extracted_keyword.name)
      end

      def notify_admins(type, mail, list, keyword, arguments, response)
        msg = I18n.t("keyword_handlers.keyword_admin_notify.#{type}",
                      sender: mail.signer,
                      keyword: keyword,
                      arguments: arguments.join(' '),
                      response: Array(response).join("\n\n")
                    )
        list.logger.notify_admin(msg, nil, 'Notice')
      end

      def check_mandatory_keywords(mail)
        # If no keyword is present, then the mandatory ones don't need to be
        # present, either.
        if mail.keywords.present? && ! list_name_keyword_present?(mail)
          I18n.t(:missing_listname_keyword_error)
        else
          nil
        end
      end

      def list_name_keyword_present?(mail)
        # Check for the keyword handler class instead of the keyword strings,
        # so we don't have to repeat the spelling variants of the keyword.
        mail.keywords.map(&:class).include?(Schleuder::KeywordHandlers::ListName)
      end

      def is_reserved_keyword?(extracted_keyword)
        RESERVED_KEYWORDS.include?(extracted_keyword.name)
      end

      def assert_valid_input!(type:, keyword:, handler_class:)
        assert_valid_type!(type)
        assert_valid_keyword!(keyword)
        assert_valid_handler_class!(handler_class)
        #assert_valid_handler_method!(handler_method)
        #assert_valid_wanted_arguments!(wanted_arguments)
      end

      def assert_valid_type!(type)
        if ! REGISTERED_KEYWORDS.keys.include?(type)
          raise ArgumentError.new("Argument must be one of #{REGISTERED_KEYWORDS.keys.inspect}, got: #{type.inspect}")
        end
      end

      def assert_valid_keyword!(keyword)
        if keyword.blank?
          raise ArgumentError.new("Invalid keyword: #{keyword.inspect}")
        end
      end

      def assert_valid_handler_class!(handler_class)
        if ! handler_class.is_a?(Class)
          raise ArgumentError.new("Invalid input for handler_class: #{handler_class.inspect} is not a class")
        end
      end

      def assert_valid_handler_method!(handler_method)
        if handler_method.blank?
          raise ArgumentError.new("Invalid input for handler_method: #{handler_method.inspect} is not a valid method name")
        end
      end

      def assert_valid_wanted_arguments!(wanted_arguments)
        valid = case wanted_arguments
                when []
                  true
                when Array
                  wanted_arguments.map(&:class).uniq == [Regexp]
                else
                  false
                end

        if ! valid
          raise ArgumentError.new("Invalid input for wanted_arguments: #{wanted_arguments.inspect} is not an array of regular expressions")
        end
      end
    end
  end
end
