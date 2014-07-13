module Schleuder
  module Plugins
    def self.run(keyword, arguments, mail)
      command = keyword.gsub('-', '_')
      if Plugins.respond_to?(command)
        Plugins.send(command, arguments, mail)
      else
        I18n.t('plugins.unknown_keyword', keyword: keyword)
      end
    rescue => exc
      # Log to system, this information is probably more useful for
      # system-admins than for list-admins.
      Schleuder.logger.error(exc)
      I18n.t("plugins.plugin_failed", keyword: keyword)
    end
  end
end
