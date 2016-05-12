module Schleuder
  module Filters

    def self.forward_all_incoming_to_admins(list, mail)
      if list.forward_all_incoming_to_admins
        list.logger.notify_admin I18n.t(:forward_all_incoming_to_admins), mail.original_message, I18n.t('incoming_message')
      end
    end

  end
end


