module Schleuder
  module KeywordHandlers
    class Base
      SEPARATORS = /[,;\s]/
      class << self
        # TODO: make wanted_arguments a mandatory argument
        def handles_request_keyword(keyword, with_method:, wanted_arguments: [], has_aliases: [])
          KeywordHandlersRunner.register_keyword(
            type: :request,
            keyword: keyword,
            handler_class: self,
            handler_method: with_method,
            wanted_arguments: wanted_arguments,
            aliases: has_aliases
          )
        end

        # TODO: make wanted_arguments a mandatory argument
        def handles_list_keyword(keyword, with_method:, wanted_arguments: [], has_aliases: [])
          KeywordHandlersRunner.register_keyword(
            type: :list,
            keyword: keyword,
            handler_class: self,
            handler_method: with_method,
            wanted_arguments: wanted_arguments,
            aliases: has_aliases
          )
        end
      end

      attr_reader :arguments
      attr_reader :mail

      def initialize(mail:, arguments:)
        @arguments = arguments
        @mail = mail
        @list = mail.list
      end

      private

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
