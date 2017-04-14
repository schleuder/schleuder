module Schleuder
  module PluginRunners
    module ListPluginsRunner
      extend Base

      def self.notify_admins(keyword, arguments, response)
        msg = I18n.t('plugins.keyword_admin_notify_lists',
                                signer: @mail.signer,
                                keyword: keyword,
                                arguments: arguments
                            )
        @list.logger.notify_admin(msg, nil, 'Notice')
      end

      # TODO: do we really need this? Does any plugin depend on it? And if, is it really the best way to report errors?
      def self.run_command(command, arguments)
        response = super(command, arguments)
        # Any output will be treated as error-message. Text meant for users
        # should have been put into the mail by the plugin.
        if response.present?
          @mail.add_pseudoheader(:error, response.to_s)
        end
        nil
      end
    end
  end
end
