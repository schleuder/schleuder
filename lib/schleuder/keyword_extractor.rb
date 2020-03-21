module Schleuder
  class KeywordExtractor
    class << self
      def extract_keywords(keywords_type, content_lines)
        known_keywords = KeywordHandlersRunner.known_keywords(keywords_type)

        extracted_keywords = []
        in_keyword_block = false
        content_lines.each_with_index do |line, i|
          if match = line.match(/^x-([-a-z]+)([:\s]+(.*)|$)/i)
            # Always strip this line from the content, regardless of whether
            # the arguments are valid: we don't want to leak data.
            content_lines[i] = nil
            # By default, don't look further for arguments for the current keyword.
            in_keyword_block = false

            # TODO: beware: known_keywords contains e.g. x-list-name, which is not registered but implicitly defined.
            current_keyword = match[1].strip.downcase
            if known_keywords[current_keyword].blank?
              raise Errors::UnknownKeyword.new(current_keyword)
            end
            # match[2] is an artefact of the regexp used above, we don't need it.
            arguments = into_arguments(match[3])
            wanted_arguments = known_keywords[current_keyword][:wanted_arguments]

            extracted_keyword = ExtractedKeyword.new(current_keyword, arguments, wanted_arguments)

            if extracted_keyword.all_arguments_met?
              pp 'all met!'
            else
              pp 'not all met'
              if extracted_keyword.wants_more?
                pp 'wants more'
                in_keyword_block = true
              else
                if ! extracted_keyword.mandatory_arguments_met?
                  # TODO: proper error that explains the wanted arguments.
                  raise "Error: Missing arguments to keyword '#{current_keyword}'"
                end
              end
            end

            extracted_keywords << extracted_keyword

          elsif in_keyword_block == true
            # Break on blank lines.
            if line.blank?
              break
            end

            pp "next line: #{line}"
            # Try to interpret this line as arguments to the keyword from the previous line.
            testing_ex_kw = extracted_keywords[-1].dup
            testing_ex_kw.add_arguments(into_arguments(line))

            if testing_ex_kw.all_arguments_met?
              pp 'all args met'
              in_keyword_block = false
              content_lines[i] = nil
              extracted_keywords[-1] = testing_ex_kw
              next
            end

            if testing_ex_kw.wants_more?
              content_lines[i] = nil
              extracted_keywords[-1] = testing_ex_kw
              pp 'wants more'
            else
              pp 'not more'
              in_keyword_block = false
              if ! testing_ex_kw.mandatory_arguments_met?
                # TODO: proper error that explains the wanted arguments.
                raise "Error: Missing arguments to keyword '#{extracted_keywords[-1].name}'"
              end
            end
          end
        end
        [extracted_keywords, content_lines.compact]
      end

      def into_arguments(string)
        string.to_s.strip.downcase.split(/[,;\s]+/)
      end
    end
  end
end
