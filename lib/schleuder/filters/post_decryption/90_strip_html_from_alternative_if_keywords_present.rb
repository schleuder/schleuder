module Schleuder
  module Filters

    # If keywords are present, recurse into arbitrary levels of multipart/mixed
    # encapsulation. If multipart/alternative is found, remove all sub-parts
    # but the text/plain part (assuming that every multipart/alternative
    # contains exactly one text/plain). Change the content_type from
    # multipart/alternative to multipart/mixed.
    def self.strip_html_from_alternative_if_keywords_present(list, mail)
      # Only strip the text/html-part if keywords are present
      if mail.keywords.blank? then return false end
      return self.recursively_strip_html_from_alternative_if_keywords_present(list, mail)
    end

    def self.recursively_strip_html_from_alternative_if_keywords_present(list, mail)
      if mail[:content_type].blank? then return false end
      content_type = mail[:content_type].content_type

      # The multipart/alternative could hide inside an arbitrary number of
      # levels of multipart/mixed encapsulation.
      # see also: https://www.rfc-editor.org/rfc/rfc2046#section-5.1.3
      if content_type == 'multipart/mixed'
        mail.parts.each do |part|
          self.recursively_strip_html_from_alternative_if_keywords_present(list, part)
        end
        return false
      end

      # inside the multipart/mixed, we only care about multipart/mixed and
      # multipart/alternative
      if content_type != 'multipart/alternative' then return false end

      # Inside multipart/alternative, there could be a text/html-part, or there
      # could be a multipart/related-part which contains the text/html-part.
      # Everything inside the multipart/alternative that is not text/plain
      # should be deleted, since it will contain keywords and we only strip
      # keywords from text/plain-parts.
      Schleuder.logger.debug 'Stripping html-part from multipart/alternative-message because it contains keywords'
      mail.parts.delete_if do |part|
        content_type = part[:content_type].content_type
        content_type != 'text/plain'
      end

      # NOTE: We could instead unencapsulate it.
      mail.content_type = 'multipart/mixed'

      mail.add_pseudoheader(:note, I18n.t('pseudoheaders.stripped_html_from_multialt_with_keywords'))
    end
  end
end



