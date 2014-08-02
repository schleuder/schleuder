module Schleuder
  module Plugins
    def self.add_key(arguments, list, mail)
      list.import_key(mail.parts.first || mail.body)
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
        end.join("\n\n")
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
