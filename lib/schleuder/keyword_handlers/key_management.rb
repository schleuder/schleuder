module Schleuder
  module KeywordHandlers
    class KeyManagement < Base
      handles_request_keyword "add-key", with_method: "add_key"
      handles_request_keyword "delete-key", with_method: "delete_key"
      handles_request_keyword "list-keys", with_method: "list_keys"
      handles_request_keyword "get-key", with_method: "get_key"
      handles_request_keyword "fetch-key", with_method: "fetch_key"

      def add_key
        key_material = find_key_material

        if key_material.blank?
          @list.logger.debug "Found no key material in message - sending error message"
          return t("no_content_found")
        end

        output = Array(key_material).map do |importable|
          keys_controller.import(@list.email, importable)
        end

        output.flatten.join("\n\n")
      end

      def delete_key
        if @arguments.blank?
          return t("delete_key_requires_arguments")
        end

        @arguments.map do |argument|
          key = keys_controller.delete(@list.email, argument)
          t("deleted", key_string: key.summary)
        rescue GPGME::Error::Conflict => exc
          t("not_deletable", error: exc.message)
        rescue Errors::KeyNotFound => exc
          exc.to_s
        end.join("\n\n")
      end

      def list_keys
        arguments = Array(@arguments.presence || "")
        arguments.map do |argument|
          keys = keys_controller.find_all(@list.email, argument)

          if keys.size > 0
            keys.each do |key|
              key.to_s
            end.join("\n\n")
          else
            t("no_matching_keys", input: argument)
          end
        end.join("\n\n")
      end

      def get_key
        @arguments.map do |argument|
          keys = keys_controller.find_all(@list.email, argument)

          if keys.blank?
            t("no_matching_keys", input: argument)
          else
            result = [t("matching_keys_intro", input: argument)]
            keys.each do |key|
              result << make_key_attachment(key)
            end
            result.flatten
          end
        end.join("\n\n")
      end

      def fetch_key
        argument = @arguments.first
        if argument.blank?
          return t("fetch_key_requires_arguments")
        end

        keys_controller.fetch(@list.email, argument)
      end

      private

      def make_key_attachment(key)
        attachment = Mail::Part.new
        attachment.body = key.armored
        attachment.content_type = "application/pgp-keys"
        attachment.content_disposition = "attachment; filename=#{key.fingerprint}.asc"
        attachment
      end

      def find_key_material
        if @mail.has_attachments?
          @mail.attachments.map { |attachment| attachment.body.decoded }
        elsif @mail.first_plaintext_part.body.to_s.present?
          @mail.first_plaintext_part.body.to_s
        end
      end
    end
  end
end
