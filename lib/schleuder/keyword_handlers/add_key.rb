module Schleuder
  module KeywordHandlers
    class AddKey < Base
      handles_request_keyword 'add-key', with_arguments: []

      def run
        key_material = if @mail.has_attachments?
                         @mail.attachments.map { |attachment| attachment.body.to_s }
                       elsif @mail.first_plaintext_part.body.to_s.present?
                         @mail.first_plaintext_part.body.to_s
                       else
                         nil
                       end
        
        if key_material.blank?
          @list.logger.debug 'Found no key material in message - sending error message'
          return t('no_content_found')
        end

        import_results = Array(key_material).map do |importable|
          keys_controller.import(@list.email, importable)
        end
        import_stati = import_results.compact.map(&:imports).flatten

        if import_stati.blank?
          return t('no_imports')
        end

        out = []

        import_stati.each do |import_status|
          if import_status.action == 'error'
            out << t('key_import_status.error', fingerprint: import_status.fingerprint)
          else
            key = @list.gpg.find_distinct_key(import_status.fingerprint)
            if key
              out << t("key_import_status.#{import_status.action}", key_summary: key.summary)
            end
          end
        end

        out.join("\n\n")
      end
    end
  end
end

