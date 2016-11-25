module Schleuder
  module RequestPlugins
    def self.add_key(arguments, list, mail)
      key_material = if mail.parts.first.present?
                       mail.parts.first.body
                     else
                       mail.body
                     end.to_s
      result = list.import_key(key_material)

      out = [I18n.t('plugins.key_management.import_result')]
      out << result.map do |import_result|
        str = I18n.t("plugins.key_management.key_import_status.#{import_result.action}")
        "#{import_result.fpr}: #{str}"
      end
    end

    def self.delete_key(arguments, list, mail)
      arguments.map do |argument|
        # TODO: I18n
        if list.gpg.delete(argument)
          "Deleted: #{argument}."
        else
          "Not found: #{argument}."
        end
      end
    end

    def self.list_keys(arguments, list, mail)
      args = arguments.presence || ['']
      args.map do |argument|
        list.keys(argument).map do |key|
          key.to_s
        end
      end
    end

    def self.get_key(arguments, list, mail)
      arguments.map do |argument|
        list.export_key(argument)
      end
    end

    def self.fetch_key(arguments, list, mail)
      hkp = Hkp.new
      arguments.map do |argument|
        hkp.fetch_and_import(argument)
      end
    end
  end
end
