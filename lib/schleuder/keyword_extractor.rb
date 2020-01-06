module Schleuder
  class KeywordExtractor
    class << self
      def extract_keywords(keywords_type, content_lines)
        known_keywords = KeywordHandlersRunner.known_keywords(keywords_type)

        extracted_keywords = []
        in_keyword_block = false
        content_lines.each_with_index do |line, i|
          if match = line.match(/^x-([^:\s]*)[:\s]*(.*)/i)
            # TODO: raise exception if keyword is not known
            # TODO: beware: known_keywords contains e.g. x-list-name, which is not registered but implicitly defined.
            keyword = match[1].strip.downcase
            # TODO: validate  arguments with the registered regexp?
            # TODO: Use Keyword class that responds to valid_arguments()?
            arguments = match[2].to_s.strip.downcase.split(/[,; ]{1,}/)
            if known_keywords[keyword].blank?
              raise Errors::UnknownKeyword.new(keyword)
            end
            if arguments.size < known_keywords[keyword][:wanted_arguments].size
              # Less arguments given than specified (maybe due to a line break): take the next line into consideration.
              in_keyword_block = true
            end
            extracted_keywords << ExtractedKeyword.new(keyword, arguments)
            content_lines[i] = nil
          elsif in_keyword_block == true
            # Interpret line as arguments to the previous keyword.
            extracted_keywords[-1].arguments += line.downcase.strip.split(/[,; ]{1,}/)
            content_lines[i] = nil
            # Stop considering the next line as arguments if enough arguments have been collected.
            if extracted_keywords[-1].arguments.size == known_keywords[extracted_keywords[-1].name][:wanted_arguments].size
              in_keyword_block = false
            elsif extracted_keywords[-1].arguments.size > known_keywords[extracted_keywords[-1].name][:wanted_arguments].size
              # TODO: properly raise or return error
              raise "Error: wrong number of arguments to keyword"
            end
          end
        end
        [extracted_keywords, content_lines.compact]
      end
    end
  end
end
