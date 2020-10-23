module Schleuder
  module KeywordHandlers
    class GetKey < Base
      handles_request_keyword 'get-key', with_arguments: [/\S+/]

      def run(mail)
        argument = @arguments.first
        keys = keys_controller.find_all(@list.email, argument)

        if keys.blank?
          t('no_matching_keys', input: argument)
        else
          result = [t('matching_keys_intro', input: argument)]
          keys.each do |key|
            result << make_key_attachment(key)
          end
          result.flatten
        end
      end

      private

      def make_key_attachment(key)
        attachment = Mail::Part.new
        attachment.body = key.armored
        attachment.content_type = 'application/pgp-keys'
        attachment.content_disposition = "attachment; filename=#{key.fingerprint}.asc"
        attachment
      end
    end
  end
end
