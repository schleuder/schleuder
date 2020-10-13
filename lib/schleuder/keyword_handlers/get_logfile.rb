module Schleuder
  module KeywordHandlers
    class GetLogfile < Base
      handles_request_keyword 'get-logfile'

      WANTED_ARGUMENTS = []

      def run(mail)
        logfile = lists_controller.get_logfile(mail.list.email)
        if logfile.present?
          attachment = Mail::Part.new
          attachment.body = File.read(logfile)
          attachment.content_disposition = "inline; filename=#{mail.list.email}.log"
          intro = I18n.t('keyword_handlers.list_management.logfile_attached', listname: mail.list.email)
          [intro, attachment]
        else
          I18n.t('keyword_handlers.list_management.no_logfile', listname: mail.list.email)
        end
      end
    end
  end
end
