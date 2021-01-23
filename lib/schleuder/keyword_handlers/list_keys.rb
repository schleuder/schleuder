module Schleuder
  module KeywordHandlers
    class ListKeys < Base
      handles_request_keyword 'list-keys', with_arguments: [/\S?/, /\S?/, /\S?/]

      def run
        if @arguments.blank?
          keys = keys_controller.find_all(@list.email, '')
        else
          keys = @arguments.map do |arg|
            keys_controller.find_all(@list.email, arg)
          end.flatten
        end

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
