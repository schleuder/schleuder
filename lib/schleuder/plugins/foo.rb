module Schleuder
  module ListPlugins
    def self.foo(arguments, mail)
      mail.add_pseudoheader :foo, 'Bar!'
      nil
    end
  end
end
