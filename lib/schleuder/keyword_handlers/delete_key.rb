module Schleuder
  module KeywordHandlers
    class DeleteKey < Base
      handles_request_keyword 'delete-key'

      WANTED_ARGUMENTS = [/\S+/]

      def run(mail)
        # TODO: Do we still need this check?
        if @arguments.blank?
          return t('delete_key_requires_arguments')
        end

        argument = arguments.first
        begin
          key = keys_controller.delete(mail.list.email, argument)
          t('deleted', key_string: key.summary)
        rescue GPGME::Error::Conflict => exc
          t('not_deletable', error: exc.message)
        rescue Errors::KeyNotFound => exc
          exc.to_s
        end
      end
    end
  end
end
