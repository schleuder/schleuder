module Schleuder
  class WkdClient < Http
    class << self
      def get(emailaddr)
        urls = wkd_urls(emailaddr)
        urls.each do |url|
          begin
            result = new(url).run
            if ! result.is_a?(StandardError)
              return result
            end
          rescue NetworkError => error
          end
        end
        return false
      end

      private

      def wkd_urls(emailaddr)
        local_part, domain = emailaddr.split('@', 2)
        [
          File.join("https://openpgpkey.#{domain}", '.well-known', 'openpgpkey', domain, 'hu', wkd_hash(local_part)) + "?l=#{ERB::Util.url_encode(local_part)}",
          File.join("https://#{domain}", '.well-known', 'openpgpkey', 'hu', wkd_hash(local_part))
        ]
      end

      def wkd_hash(string)
        # Table for z-base-32 encoding.
        Base32.table = "ybndrfg8ejkmcpqxot1uwisza345h769"
        Base32.encode(Digest::SHA1.digest(string.downcase))
      end
    end
  end
end
