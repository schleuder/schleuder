module Schleuder
  module KeywordHandlers
    class ListManagement < Base
      handles_request_keyword 'get-logfile', with_method: 'get_logfile'

      def get_logfile
        logfile = lists_controller.get_logfile(@list.email)
        if logfile.present?
          attachment = Mail::Part.new
          attachment.body = File.read(logfile)
          attachment.content_disposition = "inline; filename=#{@list.email}.log"
          intro = I18n.t('keyword_handlers.list_management.logfile_attached', listname: @list.email)
          [intro, attachment]
        else
          I18n.t('keyword_handlers.list_management.no_logfile', listname: @list.email)
        end
      end
    end
  end
end
