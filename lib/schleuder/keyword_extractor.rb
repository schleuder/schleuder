module Schleuder
  class KeywordExtractor
    class << self
      def extract_keywords(keywords_type, content_lines)
        known_keywords = KeywordHandlersRunner.known_keywords(keywords_type)

        extracted_keywords = []
        in_keyword_block = false
        content_lines.each_with_index do |line, i|
          if match = line.match(/^x-([-a-z]+)([:\s]+(.*)|$)/i)
            # TODO: beware: known_keywords contains e.g. x-list-name, which is not registered but implicitly defined.
            current_keyword = match[1].strip.downcase
            if known_keywords[current_keyword].blank?
              raise Errors::UnknownKeyword.new(current_keyword)
            end
            # match[2] is an artefact of the regexp used above, we don't need it.
            argument_string = match[3]
            keyword_arguments_regexp = known_keywords[current_keyword][:wanted_arguments]
            extracted_keyword = ExtractedKeyword.new(current_keyword, keyword_arguments_regexp)
            # Also include the next line if the current argument_string is
            # empty: maybe the next word was very long and was already wrapped
            # onto the next line.
            if argument_string == '' || extracted_keyword.append_if_valid_arguments?(argument_string)
              in_keyword_block = true
              extracted_keywords << extracted_keyword
            else
              raise "Error: Missing arguments to keyword '#{current_keyword}'"
            end
            # Always strip this line from the content, regardless of whether
            # the arguments are valid: we don't want to leak data.
            content_lines[i] = nil
          elsif in_keyword_block == true
            # Try to interpret this line as arguments to the keyword from the previous line.
            if extracted_keywords[-1].append_if_valid_arguments?(line)
              content_lines[i] = nil
            else
              if !extracted_keywords[-1].arguments_valid?
                raise "Error: Missing arguments to keyword '#{extracted_keywords[-1].name}'"
              else
                in_keyword_block = false
                keyword_arguments_regexp = nil
              end
            end
          end
        end
        [extracted_keywords, content_lines.compact]
      end
    end
  end
end
