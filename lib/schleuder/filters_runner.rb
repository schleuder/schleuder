module Schleuder
  module Filters
    class Runner
      # To define priority sort this.
      FILTERS = %w[
        send_key
        forward_to_owner
        max_message_size
        receive_admin_only
        receive_authenticated_only
        receive_signed_only
        receive_encrypted_only
        receive_from_subscribed_emailaddresses_only
      ]

      def self.run(list, mail)
        @list = list
        @mail = mail
        FILTERS.map do |cmd|
          Schleuder.logger.debug "Calling filter #{cmd}"
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
          logger.debug "Dropping bounce as configurated"
          return false
        end

        @list.bounces_drop_on_headers.each do |key, value|
          if @mail.headers[key].to_s.match(/${value}/i)
            logger.debug "Incoming message header key '#{key}' matches value '#{value}': dropping the bounce."
            return false
          end
        end

        logger.debug "Bouncing message"
        true
      end
    end
  end
end
