module Schleuder
  module PluginRunners
    module RequestPluginsRunner
      extend Base

      def self.notify_admins(keyword, arguments, response)
        if arguments.blank?
          explanation = I18n.t('plugins.keyword_admin_notify_request_without_arguments',
                                signer: @mail.signer,
                                keyword: keyword
                            )
        else
          explanation = I18n.t('plugins.keyword_admin_notify_request',
                                signer: @mail.signer,
                                keyword: keyword,
                                arguments: arguments.join(' ')
                            )
        end
        response = response.join("\n\n")
        msg = "#{explanation}\n\n#{response}"
        @list.logger.notify_admin(msg, nil, 'Notice')
      end

    end
  end
end

