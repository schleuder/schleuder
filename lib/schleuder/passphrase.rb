require 'base64'
module Schleuder
  # generate a passphrase

  class Passphrase

    @@random_source="/dev/urandom"

    def initialize
      if ! File.exists?(@@random_source)
        # oehm ...
        # TODO better error handling
        return nil 
      end
    end

    def generate(size)
      @phrase=nil
      File.open(@@random_source,"r") do |file|
        bytes=file.read(size)
        @phrase=Base64.encode64(bytes)
      end
    end

    def readout
      @phrase
    end

  end
end

# some test

# phrase = Schleuder::Passphrase.new()
# puts phrase.generate(32)
# puts phrase.readout
