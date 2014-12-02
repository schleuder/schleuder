module Schleuder
  module Filters
    def self.forward_to_owner(list, mail)
      return if ! mail.to_owner?

      Schleuder.logger.debug "Forwarding addressed to -owner"
      mail.add_pseudoheader(:note, I18n.t(:owner_forward_prefix))
      cleanmail = mail.clean_copy(list, true)
      list.admins.each do |admin|
        Schleuder.logger.debug "Forwarding message to #{admin}"
        admin.send_mail(cleanmail).deliver
      end
      exit
    end
  end
end

