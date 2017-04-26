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

    end
  end
end
