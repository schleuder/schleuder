module Schleuder
  module Filters
    class Runner
      # To define priority sort this.
      FILTERS = %w[
        request
        forward_bounce_to_admins
        forward_all_incoming_to_admins
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
          @list.logger.debug "Calling filter #{cmd}"
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
          @list.logger.debug "Dropping bounce as configurated"
          notify_admins(I18n.t('.bounces_drop_all'))
          return false
        end

        @list.bounces_drop_on_headers.each do |key, value|
          if @mail.headers[key].to_s.match(/${value}/i)
            @list.logger.debug "Incoming message header key '#{key}' matches value '#{value}': dropping the bounce."
            notify_admins(I18n.t('.bounces_drop_on_headers', key: key, value: value))
            return false
          end
        end

        @list.logger.debug "Bouncing message"
        true
      end

      def self.notify_admins(reason)
        if @list.bounces_notify_admins?
          @list.logger.notify_admin reason, @mail, I18n.t('notice')
        end
      end

      def self.reply_to_sender(msg)
        sender_addr = @mail.from.first
        logger.debug "Replying to #{sender_addr.inspect}"
        reply = @mail.reply
        reply.from = @list.email
        reply.return_path = @list.bounce_address
        reply.body = msg
        gpg_opts = {sign: true}
        if @list.keys("<#{sender_addr}>").present?
          logger.debug "Found key for address"
          gpg_opts[encrypt] = true
        end
        reply.gpg gpg_opts
        list.logger.info "Sending message to #{sender_addr}"
        reply.deliver
      end
    end
  end
end
