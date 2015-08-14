module Schleuder
  module Filters
    def self.forward_bounce_to_admins(list, mail)
      if mail.bounce?
        Schleuder.logger.info "Forwarding bounce to admins"
        Schleuder.logger.notify_admin I18n.t(:forward_bounce_to_admins), mail.to_s, I18n.t('bounce')
        exit
      end
    end
  end
end

