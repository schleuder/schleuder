module Schleuder
  module Filters

    def self.fix_hotmail_messages!(list, mail)
      if mail.header['X-OriginatorOrg'].to_s.match(/(hotmail|outlook).com/) &&
          mail.parts[0][:content_type].content_type == 'text/plain' &&
          mail.parts[0].body.to_s.blank? &&
          mail.parts[1][:content_type].content_type == 'application/pgp-encrypted' &&
          mail.parts[2][:content_type].content_type == 'application/octet-stream'
        mail.parts.delete_at(0)
        mail.content_type = [:multipart, :encrypted, {protocol: "application/pgp-encrypted", boundary: mail.boundary}]
      end
    end
  end
end


