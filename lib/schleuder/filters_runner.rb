module Schleuder
  module Filters
    class Runner
      # To define priority sort this.
      Filters = %w[
        send_key
        forward_to_owner
        receive_signed_only
      ]

      def self.run(list, mail)
        @list = list
        @mail = mail
        Filters.map do |cmd|
          Schleuder.logger.debug "Calling filter #{filter}"
          error = Filters.send(cmd, list, mail)
          return error if bounce?(error)
        end
        nil
      end

      def self.bounce?(error)
        if ! error.kind_of?(StandardError)
          return false
        end

        # TODO: notify admins
        if @list.bounces_drop_all
          Schleuder.log.info "Dropping bounce as configurated"
          return false
        end

        @list.bounces_drop_on_headers.each do |key, value|
          if @mail.headers[key].match(/${value}/i)
            Schleuder.log.info "Incoming message header key '#{key}' matches value '#{value}': dropping the bounce."
            return false
          end
        end

        true
      end
    end
  end
end