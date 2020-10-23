module Schleuder
  module KeywordHandlers
    class ListKeys < Base
      handles_request_keyword 'list-keys', with_arguments: [/\S*/]

      def run
        argument = Array(@arguments.first.presence || '')
        keys = keys_controller.find_all(@list.email, argument)

        if keys.size > 0
          keys.each do |key|
            key.to_s
          end.join("\n\n")
        else
          t('no_matching_keys', input: argument)
        end
      end
    end
  end
end
