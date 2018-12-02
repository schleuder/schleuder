module Schleuder
  module RequestPlugins
    def self.get_logfile(arguments, list, mail)
      if File.readable?(list.logfile)
        attachment = Mail::Part.new
        attachment.body = File.read(list.logfile)
        attachment.content_disposition = "inline; filename=#{list.email}.log"
        intro = I18n.t('plugins.list_management.logfile_attached', listname: list.email)
        [intro, attachment]
      else
        I18n.t('plugins.list_management.no_logfile', listname: list.email)
      end
    end
  end
end
