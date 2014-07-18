module Schleuder
  module Plugins
    def self.add_key(arguments, list, mail)
      list.import_key(mail.parts.first || mail.body)
    end

    def self.delete_key(arguments, list, mail)
      with_split_args(arguments).each do |argument|
        list.gpg.delete(argument)
      end
    end

    def self.list_keys(arguments, list, mail)
      with_split_args(arguments).each do |argument|
        list.keys(argument).map do |key|
          key.to_s
        end
      end
    end

    def self.get_key(arguments, list, mail)
      with_split_args(arguments).each do |argument|
        GPGME::Key.export(argument)
      end
    end

    def self.fetch_key(arguments, list, mail)
      hkp = Hkp.new
      with_split_args(arguments).each do |argument|
        hkp.fetch_and_import(argument)
      end
    end
  end
end
