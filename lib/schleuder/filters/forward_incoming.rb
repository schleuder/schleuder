module Schleuder
  module Filters

    def self.forward_all_incoming_to_admins(list, mail)
      if list.forward_all_incoming_to_admins
        Schleuder.logger.notify_admin I18n.t(:forward_all_incoming_to_admins), mail.raw_source, I18n.t('incoming_message')
      end
    end

  end
end


