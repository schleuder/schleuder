module Schleuder
  module KeywordHandlers
    class Base
      SEPARATORS = /[,;\s]/
      class << self
        def handles_request_keyword(keyword, with_arguments:)
          @wanted_arguments = with_arguments
          KeywordHandlersRunner.register_keyword(
            type: :request,
            keyword: keyword,
            handler_class: self
          )
        end

        def handles_list_keyword(keyword, with_arguments:)
          @wanted_arguments = with_arguments
          KeywordHandlersRunner.register_keyword(
            type: :list,
            keyword: keyword,
            handler_class: self
          )
        end

        def wanted_arguments
          @wanted_arguments
        end
      end

      attr_reader :arguments, :invalid_arguments

      def initialize(called_keyword)
        @called_keyword = called_keyword
        @arguments = []
        @invalid_arguments = []
      end

      def name
        @called_keyword
      end

      def consume_arguments(input)
        args_to_check = @arguments + into_arguments(input)
        action, args_to_save = validate_arguments(args_to_check.dup)
        case action
        when :more
          @arguments = args_to_save || args_to_check
          :more
        when :invalid
          # Save invalid arguments to enable run() to produce sensible error messages.
          @invalid_arguments = args_to_check
          :invalid
        when :end
          @arguments = args_to_save || args_to_check
          :end
        end
      end

      def validate_arguments(arguments)
        if arguments.size > self.class.wanted_arguments.size
          return :invalid
        end

        arguments.each_with_index do |argument, index|
          match_data = argument.match(self.class.wanted_arguments[index])
          # TODO: does this work for keywords that allow the first argument to be blank?
          # Reject also empty matches, which are produced by optional arguments.
          if match_data.blank? || match_data[0].blank?
            return :invalid
          end
        end

        if arguments.size < self.class.wanted_arguments.size
          return :more
        else
          return :end
        end
      end

      def execute(mail)
        if ! self.respond_to?(:run)
          raise 'run() is not implemented for this class, cannot execute!'
        end
        @mail = mail
        @list = mail.list
        run
      end

      private

      def into_arguments(string)
        string.to_s.strip.downcase.split(/[,;\s]+/)
      end

      def lists_controller
        @lists_controller ||= ListsController.new(@mail.signer.account)
      end

      def subscriptions_controller
        @subscriptions_controller ||= SubscriptionsController.new(@mail.signer.account)
      end

      def keys_controller
        @keys_controller ||= KeysController.new(@mail.signer.account)
      end

      def authorize!(resource, action)
        @mail.signer.account.authorize!(resource, action)
      end

      def keyword_permission_error(keyword)
        I18n.t('errors.not_permitted_for_subscribers', keyword: keyword)
      end

      def t(key, args={})
        underscored_name = self.class.name.demodulize.underscore
        I18n.t("keyword_handlers.#{underscored_name}.#{key}", args)
      end
    end
  end
end
