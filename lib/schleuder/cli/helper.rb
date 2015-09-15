module Schleuder
  module Cli
    module Helper
      def getlist(listname)
        list = Schleuder::List.where(email: listname).first
        if list.blank?
          fatal "No such list."
        end
        list
      end

      def fatal(msgs)
        Array(msgs).each do |msg|
          error msg
        end
        exit 1
      end

      def show_value(value)
        case value
        when Array, Hash
          puts value.inspect
        else
          puts value
        end
        exit
      end

      def show_or_set_config(object, option, value)
        if option.blank?
          list_options(object)
        elsif value.blank?
          show_config_value(object, option)
        else
          set_config_value(object, option, value)
        end
      end

      def list_options(object)
        say "Available options:\n\n#{object.class.configurable_attributes.join("\n")}"
      end

      def show_config_value(object, option)
        if object.respond_to?(option)
          show_value object.send(option)
        else
          fatal "No such config-option: '#{option}'"
        end
      end

      def set_config_value(object, option, value)
        case value.strip
        when /\A\[.*\]\z/
          # Convert input into Array
          value = value.gsub('[', '').gsub(']', '').split(/,\s/)
        when /\A\{.*\}\z/
          # Convert input into Hash
          tmp = value.gsub('{', '').gsub('}', '').split(/,\s/)
          value = tmp.inject({}) do |hash, pair|
            k,v = pair.split(/:\s|=>\s/)
            hash[k.strip] = v.strip
            hash
          end
        end
        object[option] = value
        if object.save
          show_value object.send(option)
        else
          object.errors.each do |attrib, message|
            error "#{attrib} #{message}"
          end
        end
      end

    end
  end
end

