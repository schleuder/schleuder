module Schleuder
  module Filters
    def self.strip_html_from_alternative_if_keywords_present(list, mail)
      if mail[:content_type].blank? ||
          mail[:content_type].content_type != 'multipart/alternative' ||
          mail.keywords.blank?
        return false
      end

      Schleuder.logger.debug 'Stripping html-part from multipart/alternative-message because it contains keywords'
      mail.parts.delete_if do |part|
        part[:content_type].content_type == 'text/html'
      end
      mail.content_type = 'multipart/mixed'
      mail.add_pseudoheader(:note, I18n.t('pseudoheaders.stripped_html_from_multialt_with_keywords'))
    end
  end
end



