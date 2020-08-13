module Schleuder
  module KeywordHandlers
    class ListName < Base
      handles_list_keyword 'list-name'
      handles_list_keyword 'listname'
      handles_request_keyword 'list-name'
      handles_request_keyword 'listname'

      WANTED_ARGUMENTS = [Conf::EMAIL_REGEXP]

      def run(mail)
        if ! [mail.list.email, mail.list.request_address].include?(@arguments.first)
          raise I18n.t(:wrong_listname_keyword_error)
        end
      end
    end
  end
end
