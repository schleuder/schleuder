module Schleuder
  class KeywordExtractor
    class << self
      def extract_keywords(keywords_type, content_lines)
        known_keywords = KeywordHandlersRunner.known_keywords(keywords_type)

        extracted_keywords = []
        in_keyword_block = false
        content_lines.each_with_index do |line, i|
          # The second regexp group is an artefact we don't actually need.
          # I didn't find a different way to match both, keyword-lines that end
          # immediately without a colon or space or argument (e.g.  x-add-key),
          # and keyword-lines that do contain a colon or space or arguments. 
          if match = line.match(/^x-(?<name>[-a-z]+)([:\s]+(?<argstring>.*)|$)/i)
            # Always strip this line from the content, regardless of whether
            # the arguments are valid: we don't want to leak data.
            content_lines[i] = nil
            # By default, don't look further for arguments for the current keyword.
            in_keyword_block = false

            # TODO: beware: known_keywords contains e.g. x-list-name, which is not registered but implicitly defined.

            current_keyword = match[:name].strip.downcase
            if known_keywords[current_keyword].blank?
              raise Errors::UnknownKeyword.new(current_keyword)
            end

            extracted_keywords << known_keywords[current_keyword].new(current_keyword)

            if extracted_keywords[-1].consume_arguments(match[:argstring]) == :more
              in_keyword_block = true
            end

          elsif in_keyword_block == true
            # Try to interpret this line as arguments to the current keyword.
            
            # Stop parsing completely at blank lines.
            break if line.blank?

            case extracted_keywords[-1].consume_arguments(line)
            when :more
              # Remove this line from the content and continue to look for more arguments for the current keyword.
              content_lines[i] = nil
            when :invalid
              # Keep this line in the content and stop looking for more arguments for the current keyword.
              in_keyword_block = false
            when :end
              # Remove line from content but also stop looking for more arguments for the current keyword.
              content_lines[i] = nil
              in_keyword_block = false
            end
          end
        end
        [extracted_keywords, content_lines.compact]
      end
    end
  end
end
