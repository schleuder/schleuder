module Schleuder
  module KeywordHandlers
    class FetchKey < Base
      handles_request_keyword 'fetch-key', with_arguments: [/\S+/]

      def run(mail)
        argument = @arguments.first
        if argument.blank?
          return t('fetch_key_requires_arguments')
        end

        keys_controller.fetch(@list.email, argument)
      end
    end
  end
end
