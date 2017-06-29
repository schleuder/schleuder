require "spec_helper"

describe Schleuder::Filters do

  context '.fix_hostmail_messages!' do
    it "fixes pgp/mime-messages that were mangled by hotmail" do
      message = Mail.read("spec/fixtures/mails/hotmail.eml")
      Schleuder::Filters.fix_hotmail_messages!(nil, message)

      expect(message[:content_type].content_type).to eql("multipart/encrypted")
    end
  end

  context '.strip_html_from_alternative!' do
    it "strips HTML-part from multipart/alternative-message that contains ascii-armored PGP-data" do
      list = create(:list)
      mail = Mail.new
      mail.to = list.email
      mail.from = 'outside@example.org'
      content = encrypt_string(list, "blabla")
      mail.text_part = content
      mail.html_part = "<p>#{content}</p>"
      mail.subject = "test"

      Schleuder::Filters.strip_html_from_alternative!(list, mail)

      expect(mail[:content_type].content_type).to eql("multipart/mixed")
      expect(mail.parts.size).to be(1)
      expect(mail.parts.first[:content_type].content_type).to eql("text/plain")
      expect(mail.dynamic_pseudoheaders).to include("Note: This message included an alternating HTML-part that contained PGP-data. The HTML-part was removed to enable parsing the message more properly.")
    end

    it "does NOT strip HTML-part from multipart/alternative-message that does NOT contain ascii-armored PGP-data" do
      mail = Mail.new
      mail.to = 'schleuder@example.org'
      mail.from = 'outside@example.org'
      content = "blabla"
      mail.text_part = content
      mail.html_part = "<p>#{content}</p>"
      mail.subject = "test"

      Schleuder::Filters.strip_html_from_alternative!(nil, mail)

      expect(mail[:content_type].content_type).to eql("multipart/alternative")
      expect(mail.parts.size).to be(2)
      expect(mail.parts.first[:content_type].content_type).to eql("text/plain")
      expect(mail.parts.last[:content_type].content_type).to eql("text/html")
      expect(mail.dynamic_pseudoheaders).not_to include("Note: This message included an alternating HTML-part that contained PGP-data. The HTML-part was removed to enable parsing the message more properly.")
    end
  end

end
