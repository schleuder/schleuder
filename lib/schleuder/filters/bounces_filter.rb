module Schleuder
  module Filters
    def self.forward_bounce_to_admins(list, mail)
      if mail.bounce?
        list.logger.info "Forwarding bounce to admins"
        list.logger.notify_admin I18n.t(:forward_bounce_to_admins), mail.to_s, I18n.t('bounce')
        exit
      end
    end
  end
end

