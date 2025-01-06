require 'spec_helper'

describe Schleuder::Filters do
  before do
    # Make sure we have the filters loaded, as they will be loaded lazily within the code.
    list = create(:list)
    Schleuder::Filters::Runner.new(list, 'pre').filters
    Schleuder::Filters::Runner.new(list, 'post').filters
  end

  context '.fix_exchange_messages' do
    it 'fixes pgp/mime-messages that were mangled by Exchange' do
      message = Mail.read('spec/fixtures/mails/exchange.eml')
      Schleuder::Filters.fix_exchange_messages(nil, message)

      expect(message[:content_type].content_type).to eql('multipart/encrypted')
    end
    it 'works with a text/plain message' do
      message = Mail.read('spec/fixtures/mails/exchange_no_parts.eml')
      Schleuder::Filters.fix_exchange_messages(nil, message)

      expect(message[:content_type].content_type).to eql('text/plain')
    end
  end

  context '.strip_html_from_alternative' do
    it 'strips HTML-part from multipart/alternative-message that contains ascii-armored PGP-data' do
      list = create(:list)
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = 'outside@example.org'
      content = encrypt_string(list, 'blabla')
      mail.text_part = content
      mail.html_part = "<p>#{content}</p>"
      mail.subject = 'test'

      Schleuder::Filters.strip_html_from_alternative(list, mail)

      expect(mail[:content_type].content_type).to eql('multipart/mixed')
      expect(mail.parts.size).to be(1)
      expect(mail.parts.first[:content_type].content_type).to eql('text/plain')
      expect(mail.dynamic_pseudoheaders).to include("Note: This message included an alternating HTML-part that contained\n  PGP-data. The HTML-part was removed to enable parsing the message more\n  properly.")
    end

    it 'does NOT strip HTML-part from multipart/alternative-message that does NOT contain ascii-armored PGP-data' do
      mail = Mail.new
      mail.to = 'schleuder@example.org'
      mail.from = 'outside@example.org'
      content = 'blabla'
      mail.text_part = content
      mail.html_part = "<p>#{content}</p>"
      mail.subject = 'test'

      Schleuder::Filters.strip_html_from_alternative(nil, mail)

      expect(mail[:content_type].content_type).to eql('multipart/alternative')
      expect(mail.parts.size).to be(2)
      expect(mail.parts.first[:content_type].content_type).to eql('text/plain')
      expect(mail.parts.last[:content_type].content_type).to eql('text/html')
      expect(mail.dynamic_pseudoheaders).not_to include('Note: This message included an alternating HTML-part that contained PGP-data. The HTML-part was removed to enable parsing the message more properly.')
    end

    it 'does not choke on nor change a message without Content-Type-header' do
      mail = Mail.new
      mail.to = 'schleuder@example.org'
      mail.from = 'outside@example.org'
      mail.body = 'blabla'
      mail.subject = 'test'

      Schleuder::Filters.strip_html_from_alternative(nil, mail)

      expect(mail[:content_type]).to be_nil
      expect(mail.parts.size).to be(0)
      expect(mail.dynamic_pseudoheaders).not_to include('Note: This message included an alternating HTML-part that contained PGP-data. The HTML-part was removed to enable parsing the message more properly.')
    end
  end

  context '.strip_html_from_alternative_if_keywords_present' do
    it 'strips HTML-part from multipart/alternative-message that contains keywords' do
      list = create(:list)
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = 'outside@example.org'
      mail.text_part = content = 'x-resend: someone@example.org\n\nblabla'
      mail.html_part = '<p>x-resend: someone@example.org</p><p>blabla</p>'
      mail.subject = 'test'
      mail.to_s

      Schleuder::Filters.strip_html_from_alternative_if_keywords_present(list, mail)

      expect(mail[:content_type].content_type).to eql('multipart/mixed')
      expect(mail.parts.size).to be(1)
      expect(mail.parts.first[:content_type].content_type).to eql('text/plain')
      expect(mail.dynamic_pseudoheaders).to include("Note: This message included keywords and an alternating HTML-part. The\n  HTML-part was removed to prevent the disclosure of these keywords to third\n  parties.")
    end

    it 'strips related-part from encapsulated multipart/alternative-part that contains keywords' do
      list = create(:list)
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = 'outside@example.org'

      content_plain = "x-resend: someone@example.org\n\nblabla"
      content_html = '<html><head></head><body><p>x-resend: someone@example.org
                      </p><p>blabla</p></body></html>'

      # this makes the message a multipart/mixed
      mail.part :content_type => 'multipart/alternative' do |part_alter|
        part_alter.part :content_type => 'text/plain', :body => content_plain
        part_alter.part :content_type => 'multipart/related' do |part_related|
          part_related.part :content_type => 'text/html', :body => content_html
          part_related.part :content_type => 'image/png'
        end
      end

      mail.subject = 'test'
      mail.to_s

      Schleuder::Filters.strip_html_from_alternative_if_keywords_present(list, mail)

      expect(mail.parts.first[:content_type].content_type).to eql('multipart/mixed')
      expect(mail.parts.first.parts.size).to be(1)
      expect(mail.parts.first.parts.first[:content_type].content_type).to eql('text/plain')
      expect(mail.parts.first.dynamic_pseudoheaders).to include("Note: This message included keywords and an alternating HTML-part. The\n  HTML-part was removed to prevent the disclosure of these keywords to third\n  parties.")
    end

    it 'does NOT strip HTML-part from multipart/alternative-message that does NOT contain keywords' do
      list = create(:list)
      mail = Mail.new
      mail.list = list
      mail.to = 'schleuder@example.org'
      mail.from = 'outside@example.org'
      mail.text_part = content = 'Hello someone@example.org,\n\nblabla'
      mail.html_part = '<p>Hello someone@example.org,</p><p>blabla</p>'
      mail.subject = 'test'

      Schleuder::Filters.strip_html_from_alternative_if_keywords_present(list, mail)

      expect(mail[:content_type].content_type).to eql('multipart/alternative')
      expect(mail.parts.size).to be(2)
      expect(mail.parts.first[:content_type].content_type).to eql('text/plain')
      expect(mail.parts.last[:content_type].content_type).to eql('text/html')
      expect(mail.dynamic_pseudoheaders).to be_blank
    end

    it 'does not choke on nor change a message without Content-Type-header' do
      mail = Mail.new
      mail.to = 'schleuder@example.org'
      mail.from = 'outside@example.org'
      mail.body = 'blabla'
      mail.subject = 'test'

      Schleuder::Filters.strip_html_from_alternative_if_keywords_present(nil, mail)

      expect(mail[:content_type]).to be_nil
      expect(mail.parts.size).to be(0)
      expect(mail.dynamic_pseudoheaders).to be_blank
    end
  end

  context '.receive_from_subscribed_emailaddresses_only' do
    it 'does not reject a message with a non-subscribed address as From-header if list.receive_from_subscribed_emailaddresses_only is not set' do
      list = create(:list, receive_from_subscribed_emailaddresses_only: false)
      list.subscribe('admin@example.org', nil, true)
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = 'outside@example.org'

      result = Schleuder::Filters.receive_from_subscribed_emailaddresses_only(list, mail)

      expect(result).to eql(nil)
    end

    it 'rejects a message with a non-subscribed address as From-header if list.receive_from_subscribed_emailaddresses_only is set' do
      list = create(:list, receive_from_subscribed_emailaddresses_only: true)
      list.subscribe('admin@example.org', nil, true)
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = 'outside@example.org'

      result = Schleuder::Filters.receive_from_subscribed_emailaddresses_only(list, mail)

      expect(result).to be_a(Errors::MessageSenderNotSubscribed)
    end

    it 'does not reject a message with a subscribed address as From-header if list.receive_from_subscribed_emailaddresses_only is set' do
      list = create(:list, receive_from_subscribed_emailaddresses_only: true)
      list.subscribe('admin@example.org', nil, true)
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = list.subscriptions.first.email

      result = Schleuder::Filters.receive_from_subscribed_emailaddresses_only(list, mail)

      expect(result).to eql(nil)
    end

    it 'does not reject a message with a subscribed address as From-header with different letter case if list.receive_from_subscribed_emailaddresses_only is set' do
      list = create(:list, receive_from_subscribed_emailaddresses_only: true)
      list.subscribe('admin@example.org', nil, true)
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = 'AdMin@example.org'

      result = Schleuder::Filters.receive_from_subscribed_emailaddresses_only(list, mail)

      expect(result).to eql(nil)
    end
  end

  context('.key_auto_import_from_autocrypt_header') do
    it('does not import key if sender address does not match key UID, regardless of Autocrypt addr attribute') do
      keydata_base64 = Base64.encode64(File.read('spec/fixtures/bla_foo_key.txt'))
      list = create(:list, key_auto_import_from_email: true)
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = list.email
      mail.text_part = 'bla'
      mail.header['Autocrypt'] = "addr=#{list.email}; prefer-encrypt=mutual; keydata=#{keydata_base64}"
      list_keys_num = list.keys.size

      Schleuder::Filters.key_auto_import_from_autocrypt_header(list, mail)

      expect(list.keys.size).to eql(list_keys_num)
      expect(mail.dynamic_pseudoheaders.join("\n")).not_to include("Note: This key was newly added from this email:\n  0x87E65ED2081AE3D16BE4F0A5EBDBE899251F2412")
    end

    it('imports key and reports the change') do
      keydata_base64 = Base64.encode64(File.read('spec/fixtures/expired_key_extended.txt'))
      mail_from = 'schleuder <bla@foo>'
      list = create(:list, key_auto_import_from_email: true)
      list.import_key(File.read('spec/fixtures/expired_key.txt'))
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = mail_from
      mail.text_part = 'bla'
      mail.header['Autocrypt'] = "addr=#{mail_from}; prefer-encrypt=mutual; keydata=#{keydata_base64}"
      list_keys_num = list.keys.size

      Schleuder::Filters.key_auto_import_from_autocrypt_header(list, mail)

      expect(list.keys.size).to eql(list_keys_num)
      expect(mail.dynamic_pseudoheaders.join("\n")).to include("This key was updated from this email:\n  0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo 2010-08-13 [expired:\n  2017-01-20]")
    end

    it('imports key and reports no change') do
      keydata_base64 = File.read('spec/fixtures/schleuder_at_example_public_key_minimal_base64.txt')
      mail_from = 'schleuder <schleuder@example.org>'
      list = create(:list, key_auto_import_from_email: true)
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = mail_from
      mail.text_part = 'bla'
      mail.header['Autocrypt'] = "addr=#{mail_from}; prefer-encrypt=mutual; keydata=#{keydata_base64}"
      list_keys_num = list.keys.size

      Schleuder::Filters.key_auto_import_from_autocrypt_header(list, mail)

      expect(list.keys.size).to eql(list_keys_num)
      expect(mail.dynamic_pseudoheaders.join("\n")).to include("This key was unchanged from this email:\n  0x59C71FB38AEE22E091C78259D06350440F759BD3 schleuder@example.org 2016-12-06.")
    end

    it('imports key and reports new key') do
      keydata_base64 = Base64.encode64(File.read('spec/fixtures/bla_foo_key.txt'))
      mail_from = 'schleuder <bla@foo>'
      list = create(:list, key_auto_import_from_email: true)
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = mail_from
      mail.text_part = 'bla'
      mail.header['Autocrypt'] = "addr=#{mail_from}; prefer-encrypt=mutual; keydata=#{keydata_base64}"
      list_keys_num = list.keys.size

      Schleuder::Filters.key_auto_import_from_autocrypt_header(list, mail)

      expect(list.keys.size).to eql(list_keys_num + 1)
      expect(mail.dynamic_pseudoheaders.join("\n")).to include("Note: This key was newly added from this email:\n  0x87E65ED2081AE3D16BE4F0A5EBDBE899251F2412")
    end

    it('only imports the one key that matches the sender address if keydata contains more than one key') do
      tmpdir = Dir.mktmpdir
      keydata = `gpg --homedir #{tmpdir} --import spec/fixtures/bla_foo_key.txt spec/fixtures/example_key.txt  2>/dev/null ; gpg --homedir #{tmpdir} -a --export`
      FileUtils.rm_rf(tmpdir)
      keydata_base64 = Base64.encode64(keydata)
      mail_from = 'schleuder <bla@foo>'
      list = create(:list, key_auto_import_from_email: true)
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = mail_from
      mail.text_part = 'bla'
      mail.header['Autocrypt'] = "addr=#{list.email}; prefer-encrypt=mutual; keydata=#{keydata_base64}"
      list_keys_num = list.keys.size

      Schleuder::Filters.key_auto_import_from_autocrypt_header(list, mail)

      expect(list.keys.size).to eql(list_keys_num + 1)
      expect(mail.dynamic_pseudoheaders.join("\n")).to include("Note: This key was newly added from this email:\n  0x87E65ED2081AE3D16BE4F0A5EBDBE899251F2412")
    end
  end

  context('.key_auto_import_from_attachments') do
    it('does not import key if sender address does not match key UID') do
      list = create(:list, key_auto_import_from_email: true)
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = list.email
      mail.text_part = 'bla'
      mail.add_file({
        filename: 'something.pgp',
        content: File.read('spec/fixtures/bla_foo_key.txt'),
        mime_type: 'application/pgp-keys'
      })
      list_keys_num = list.keys.size

      Schleuder::Filters.key_auto_import_from_attachments(list, mail)

      expect(list.keys.size).to eql(list_keys_num)
      expect(mail.dynamic_pseudoheaders.join("\n")).not_to include("Note: This key was newly added from this email:\n  0x87E65ED2081AE3D16BE4F0A5EBDBE899251F2412")
    end

    it('imports key and reports the change') do
      mail_from = 'schleuder <bla@foo>'
      list = create(:list, key_auto_import_from_email: true)
      list.import_key(File.read('spec/fixtures/expired_key.txt'))
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = mail_from
      mail.text_part = 'bla'
      mail.add_file({
        filename: 'something.pgp',
        content: File.read('spec/fixtures/expired_key_extended.txt'),
        mime_type: 'application/pgp-keys'
      })
      list_keys_num = list.keys.size

      Schleuder::Filters.key_auto_import_from_attachments(list, mail)

      expect(list.keys.size).to eql(list_keys_num)
      expect(mail.dynamic_pseudoheaders.join("\n")).to include("This key was updated from this email:\n  0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo 2010-08-13 [expired:\n  2017-01-20]")
    end

    it('imports key and reports no change') do
      mail_from = 'schleuder <schleuder@example.org>'
      list = create(:list, key_auto_import_from_email: true)
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = mail_from
      mail.text_part = 'bla'
      mail.add_file({
        filename: 'something.pgp',
        content: File.read('spec/fixtures/schleuder_at_example_public_key.txt'),
        mime_type: 'application/pgp-keys'
      })
      list_keys_num = list.keys.size

      Schleuder::Filters.key_auto_import_from_attachments(list, mail)

      expect(list.keys.size).to eql(list_keys_num)
      expect(mail.dynamic_pseudoheaders.join("\n")).to include("This key was unchanged from this email:\n  0x59C71FB38AEE22E091C78259D06350440F759BD3 schleuder@example.org 2016-12-06.")
       
    end
    

    it('imports key and reports new key') do
      mail_from = 'schleuder <bla@foo>'
      list = create(:list, key_auto_import_from_email: true)
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = mail_from
      mail.text_part = 'bla'
      mail.add_file({
        filename: 'something.pgp',
        content: File.read('spec/fixtures/bla_foo_key.txt'),
        mime_type: 'application/pgp-keys'
      })
      list_keys_num = list.keys.size

      Schleuder::Filters.key_auto_import_from_attachments(list, mail)

      expect(list.keys.size).to eql(list_keys_num + 1)
      expect(mail.dynamic_pseudoheaders.join("\n")).to include("Note: This key was newly added from this email:\n  0x87E65ED2081AE3D16BE4F0A5EBDBE899251F2412")
    end

    it('does not import key if attachment has a different content-type than "application/pgp-keys"') do
      mail_from = 'schleuder <bla@foo>'
      list = create(:list, key_auto_import_from_email: true)
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = mail_from
      mail.text_part = 'bla'
      mail.add_file({
        filename: 'something.pgp',
        content: File.read('spec/fixtures/bla_foo_key.txt'),
        mime_type: 'text/plain'
      })
      list_keys_num = list.keys.size

      Schleuder::Filters.key_auto_import_from_attachments(list, mail)

      expect(list.keys.size).to eql(list_keys_num)
      expect(mail.dynamic_pseudoheaders.join("\n")).not_to include("Note: This key was newly added from this email:\n  0x87E65ED2081AE3D16BE4F0A5EBDBE899251F2412")
    end

    it('only imports the one key that matches the sender address if keydata contains more than one key') do
      tmpdir = Dir.mktmpdir
      keydata = `gpg --homedir #{tmpdir} --import spec/fixtures/bla_foo_key.txt spec/fixtures/example_key.txt  2>/dev/null ; gpg --homedir #{tmpdir} -a --export`
      FileUtils.rm_rf(tmpdir)
      mail_from = 'schleuder <bla@foo>'
      list = create(:list, key_auto_import_from_email: true)
      mail = Mail.new
      mail.list = list
      mail.to = list.email
      mail.from = mail_from
      mail.text_part = 'bla'
      mail.add_file({filename: 'something.pgp', content: keydata, mime_type: 'application/pgp-keys'})
      list_keys_num = list.keys.size

      Schleuder::Filters.key_auto_import_from_attachments(list, mail)

      expect(list.keys.size).to eql(list_keys_num + 1)
      expect(mail.dynamic_pseudoheaders.join("\n")).to include("Note: This key was newly added from this email:\n  0x87E65ED2081AE3D16BE4F0A5EBDBE899251F2412")
    end
  end
end
