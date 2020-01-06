module Schleuder
  module Filters
    def self.list_keywords(list, mail)
      if ! mail.was_encrypted?
        logger.debug 'Message was not encrypted, skipping keyword-handlers'
      elsif mail.was_validly_signed?
        # run KeywordHandlers
        logger.debug 'Message was encrypted and validly signed'
        # Ignore the output, any keyword-handler of type :list must handle itself how to communicate.
        KeywordHandlersRunner.run(type: :list, list: list, mail: mail).compact
      end
    end
  end
end

