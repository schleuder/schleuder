module Schleuder
  module Plugins
    def self.add_key(arguments, list, mail)
      import_result = list.import_key(mail.parts.first || mail.body)

      out = [I18n.t('plugins.key_management.import_result')]
      out << import_result.imports.map do |import_status|
        action = I18n.t("plugins.key_management.key_import_status.#{import_status.action}")
        "#{import_status.fpr}: #{action}"
      end
    end

    def self.delete_key(arguments, list, mail)
      arguments.map do |argument|
        "Deleting #{argument}: #{list.gpg.delete(argument)}"
      end
    end

    def self.list_keys(arguments, list, mail)
      arguments.map do |argument|
        list.keys(argument).map do |key|
          key.to_s
        end
      end
    end

    def self.get_key(arguments, list, mail)
      arguments.map do |argument|
        GPGME::Key.export(argument)
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
