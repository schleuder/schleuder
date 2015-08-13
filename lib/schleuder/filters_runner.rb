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
          response = Filters.send(cmd, list, mail)
          if stop?(response)
            if bounce?(response)
              return response
            else
              return nil
            end
          end
        end
        nil
      end

      def self.stop?(response)
        response.kind_of?(StandardError)
      end

      def self.bounce?(response)
        if @list.bounces_drop_all
          logger.debug "Dropping bounce as configurated"
          notify_admins(I18n.t('.bounces_drop_all'))
          return false
        end

        @list.bounces_drop_on_headers.each do |key, value|
          if @mail.headers[key].to_s.match(/${value}/i)
            logger.debug "Incoming message header key '#{key}' matches value '#{value}': dropping the bounce."
            notify_admins(I18n.t('.bounces_drop_on_headers', key: key, value: value))
            return false
          end
        end

        logger.debug "Bouncing message"
        true
      end

      def self.notify_admins(reason)
        if @list.bounces_notify_admins?
          @list.logger.notify_admin reason, @mail, I18n.t('notice')
        end
      end
    end
  end
end
