module Schleuder
  module Filters
    class Runner
      # To define priority sort this.
      # The method `setup` parses, decrypts etc.
      # the mail sent to the list. So before
      # calling setup we do all the things
      # that won't require e.g. validation of
      # the sender.
      PRE_SETUP_FILTERS = %w[
        forward_bounce_to_admins
        forward_all_incoming_to_admins
        send_key
      ]
      # message size must be checked after
      # decryption as gpg heavily compresses
      # messages.
      POST_SETUP_FILTERS = %w[
        request
        max_message_size
        forward_to_owner
        receive_admin_only
        receive_authenticated_only
        receive_signed_only
        receive_encrypted_only
        receive_from_subscribed_emailaddresses_only
      ]

      attr_reader :list

      def initialize(list)
        @list = list
      end

      def run(mail, filters)
        filters.map do |cmd|
          list.logger.debug "Calling filter #{cmd}"
          response = Filters.send(cmd, list, mail)
          if stop?(response)
            if bounce?(response, mail)
              return response
            else
              return nil
            end
          end
        end
        nil
      end
      private

      def stop?(response)
        response.kind_of?(StandardError)
      end

      def bounce?(response, mail)
        if list.bounces_drop_all
          list.logger.debug "Dropping bounce as configurated"
          notify_admins(I18n.t('.bounces_drop_all'), mail.original_message)
          return false
        end

        list.bounces_drop_on_headers.each do |key, value|
          if mail[key].to_s.match(/#{value}/i)
            list.logger.debug "Incoming message header key '#{key}' matches value '#{value}': dropping the bounce."
            notify_admins(I18n.t('.bounces_drop_on_headers', key: key, value: value), mail.original_message)
            return false
          end
        end

        list.logger.debug "Bouncing message"
        true
      end

      def notify_admins(reason, original_message)
        if list.bounces_notify_admins?
          list.logger.notify_admin reason, original_message, I18n.t('notice')
        end
      end
    end
  end
end
