module Schleuder
  module KeywordHandlers
    class Base
      SEPARATORS = /[,;\s]/
      class << self
        # TODO: make wanted_arguments a mandatory argument
        def handles_request_keyword(keyword)
          KeywordHandlersRunner.register_keyword(
            type: :request,
            keyword: keyword,
            handler_class: self
          )
        end

        # TODO: make wanted_arguments a mandatory argument
        def handles_list_keyword(keyword)
          KeywordHandlersRunner.register_keyword(
            type: :list,
            keyword: keyword,
            handler_class: self
          )
        end
      end

      def initialize(called_keyword)
        @called_keyword = called_keyword
        @arguments = []
      end

      def name
        @called_keyword
      end

      def consume_arguments(input)
        args_to_check = @arguments + into_arguments(input)
        action, args_to_save = validate_arguments(args_to_check)
        case action
        when :more
          # TODO: Maybe only ask for more content if the current line was longer than X characters?
          @arguments = args_to_save || args_to_check
          :more
        when :invalid
          :invalid
        when :end
          @arguments = args_to_save || args_to_check
          :end
        end
      end

      def validate_arguments(arguments)
        if ! Kernel.const_defined?(WANTED_ARGUMENTS)
          raise RuntimeError.new("Error: WANTED_ARGUMENTS is not set. Each keyword-handler must either define the constant WANTED_ARGUMENTS, or re-implement the method validate_arguments().")
        end

        if arguments.size > WANTED_ARGUMENTS.size
          return :invalid
        end

        arguments.each_with_index do |argument, index|
          if ! argument.match(WANTED_ARGUMENTS[index])
            return :invalid
          end
        end

        if arguments.size < WANTED_ARGUMENTS.size
          return :more
        else
          return :end
        end
      end

      private

      def into_arguments(string)
        string.to_s.strip.downcase.split(/[,;\s]+/)
      end

      def lists_controller
        @lists_controller ||= ListsController.new(mail.signer.account)
      end

      def subscriptions_controller
        @subscriptions_controller ||= SubscriptionsController.new(mail.signer.account)
      end

      def keys_controller
        @keys_controller ||= KeysController.new(mail.signer.account)
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
