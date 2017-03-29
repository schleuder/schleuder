module Schleuder
  module PluginRunners
    module RequestPluginsRunner
      extend Base

      def self.notify_admins(keyword, response)
        explanation = I18n.t('plugins.keyword_admin_notify',
                                signer: @mail.signer,
                                keyword: keyword
                            )
        msg = "#{explanation}\n\n#{response}"
        @list.logger.notify_admin(msg, nil, 'Notice')
      end

    end
  end
end

