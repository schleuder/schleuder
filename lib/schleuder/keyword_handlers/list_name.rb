module Schleuder
  module KeywordHandlers
    class ListName < Base
      handles_list_keyword 'list-name', with_arguments: [Conf::EMAIL_REGEXP]
      handles_list_keyword 'listname', with_arguments: [Conf::EMAIL_REGEXP]
      handles_request_keyword 'list-name', with_arguments: [Conf::EMAIL_REGEXP]
      handles_request_keyword 'listname', with_arguments: [Conf::EMAIL_REGEXP]

      def run
        if ! [@list.email, @list.request_address].include?(@arguments.first)
          raise Errors::ListNameWrong.new
        end
      end
    end
  end
end
