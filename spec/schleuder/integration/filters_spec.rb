require 'spec_helper'

describe 'running filters' do
  context '.max_message_size' do
    it 'bounces to big mails' do
      list = create(:list)
      list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
      ENV['GNUPGHOME'] = list.listdir
      mail = Mail.new
      mail.to = list.request_address
      mail.from = list.admins.first.email
      gpg_opts = {
        encrypt: true,
        keys: {list.request_address => list.fingerprint},
        sign: true,
        sign_as: list.admins.first.fingerprint
      }
      mail.gpg(gpg_opts)
      mail.body = '+' * (1024 * list.max_message_size_kb)
      mail.deliver

      big_email = Mail::TestMailer.deliveries.first
      Mail::TestMailer.deliveries.clear

      output = process_mail(big_email.to_s, list.email)
      expect(output.message).to include(I18n.t('errors.message_too_big', allowed_size: list.max_message_size_kb))

      teardown_list_and_mailer(list)
    end
  end
  context '.fix_exchange_messages!' do
    it 'accepts an invalid pgp/mime Exchange message' do
      list = create(:list)
      list.subscribe('admin@example.org', nil, true)
      # so we can easily parse the outgoing mail
      list.send_encrypted_only = false
      list.save

      start_smtp_daemon
      message_path = 'spec/fixtures/mails/exchange.eml'

      error = run_schleuder(:work, list.email, message_path)
      mails = Dir.glob("#{smtp_daemon_outputdir}/mail-*")

      expect(error).to be_empty
      expect(mails.size).to eq 1

      exchange = Mail.read(mails.first)

      expect(exchange.to).to eql(['admin@example.org'])
      expect(exchange.parts.first.parts.last.decoded).to include("foo\n")

      stop_smtp_daemon
    end
    it 'accepts a valid plain-text message' do
      list = create(:list)
      list.subscribe('admin@example.org', nil, true)
      # so we can easily parse the outgoing mail
      list.send_encrypted_only = false
      list.save

      start_smtp_daemon
      message_path = 'spec/fixtures/mails/exchange_no_parts.eml'

      error = run_schleuder(:work, list.email, message_path)
      mails = Dir.glob("#{smtp_daemon_outputdir}/mail-*")

      expect(error).to be_empty
      expect(mails.size).to eq 1

      exchange = Mail.read(mails.first)

      expect(exchange.to).to eql(['admin@example.org'])
      expect(exchange.parts.first.parts.last.decoded).to include('bla-vla')

      stop_smtp_daemon
    end
  end

  context '.strip_html_from_alternative!' do
    it 'strips HTML-part from multipart/alternative-message that contains ascii-armored PGP-data' do
      list = create(:list)
      list.subscribe('admin@example.org', nil, true)
      # so we can easily parse the outgoing mail
      list.send_encrypted_only = false
      list.save

      start_smtp_daemon

      mail = Mail.new
      mail.to = list.email
      mail.from = 'outside@example.org'
      content = encrypt_string(list, 'blabla')
      mail.text_part = content
      mail.html_part = "<p>#{content}</p>"
      mail.subject = 'test'

      error = nil
      with_tmpfile(mail.to_s) do |fn|
        error = run_schleuder(:work, list.email, fn)
      end
      mails = Dir.glob("#{smtp_daemon_outputdir}/mail-*")

      expect(error).to be_empty
      expect(mails.size).to eq 1

      htmlmail = Mail.read(mails.first)

      expect(htmlmail.to).to eql(['admin@example.org'])
      signed_parts = htmlmail.parts[0].parts
      expect(signed_parts[0].body.to_s).to include("Note: This message included an alternating HTML-part that contained\n  PGP-data. The HTML-part was removed to enable parsing the message more\n  properly.\n")
      # why is this double wrapped?
      expect(signed_parts[1].parts[0][:content_type].content_type).to eql('text/plain')
      expect(signed_parts[1].parts[0].body.to_s).to eql("blabla\n")

      stop_smtp_daemon
    end
    it 'does NOT strip HTML-part from multipart/alternative-message that does NOT contain ascii-armored PGP-data' do
      list = create(:list)
      list.subscribe('admin@example.org', nil, true)
      # so we can easily parse the outgoing mail
      list.send_encrypted_only = false
      list.save

      start_smtp_daemon

      mail = Mail.new
      mail.to = list.email
      mail.from = 'outside@example.org'
      content = 'blabla'
      mail.text_part = content
      mail.html_part = "<p>#{content}</p>"
      mail.subject = 'test'

      error = nil
      with_tmpfile(mail.to_s) do |fn|
        error = run_schleuder(:work, list.email, fn)
      end
      mails = Dir.glob("#{smtp_daemon_outputdir}/mail-*")

      expect(error).to be_empty
      expect(mails.size).to eq 1

      htmlmail = Mail.read(mails.first)

      expect(htmlmail.to).to eql(['admin@example.org'])
      # this is double wrapped
      signed_parts = htmlmail.parts[0].parts[1].parts
      expect(signed_parts[0][:content_type].content_type).to eql('text/plain')
      expect(signed_parts[0].body.to_s).to eql('blabla')
      expect(signed_parts[1][:content_type].content_type).to eql('text/html')
      expect(signed_parts[1].body.to_s).to eql('<p>blabla</p>')

      stop_smtp_daemon
    end
  end

  context('.key_auto_import_from_autocrypt_header') do
    it('successfully validates a signature, whose previously unknown key is in the autocrypt-header') do
      list = create(:list, send_encrypted_only: false, key_auto_import_from_email: true)
      list.subscribe('me@localhost', nil, true)
      tmp_gnupg_home = Dir.mktmpdir
      ENV['GNUPGHOME'] = tmp_gnupg_home
      gpg = GPGME::Ctx.new
      gpg.keyimport(File.read('spec/fixtures/openpgp-keys/FB18AE292FCEEBCE3BB3FBA14286EE574B92FA0A-abcde_example_org.sec'))
      keyblock = gpg.find_keys('FB18AE292FCEEBCE3BB3FBA14286EE574B92FA0A').first.export(armor: true).read
      keydata_base64 = Base64.encode64(keyblock).gsub("\n", '')
      mail = Mail.new
      mail.from = 'abcde@example.org'
      mail.body = 'something'
      mail.to = list.email
      mail.header['Autocrypt'] = "addr=schleuder@example.org; prefer-encrypt=mutual; keydata=#{keydata_base64}"
      mail.gpg({
        encrypt: false,
        sign: true,
        sign_as: 'FB18AE292FCEEBCE3BB3FBA14286EE574B92FA0A'
      })
      mail.deliver

      expect(list.keys('FB18AE292FCEEBCE3BB3FBA14286EE574B92FA0A').size).to eql(0)

      signed_email = Mail::TestMailer.deliveries.first
      Mail::TestMailer.deliveries.clear
      Schleuder::Runner.new.run(signed_email.to_s, list.email)
      mail_to_subscriber = Mail::TestMailer.deliveries.first

      pseudoheaders_part = mail_to_subscriber.parts.first.parts.first
      expect(list.keys('FB18AE292FCEEBCE3BB3FBA14286EE574B92FA0A').size).to eql(1)
      expect(pseudoheaders_part.body.to_s).to include("Note: This key was newly added from this email:\n  0xFB18AE292FCEEBCE3BB3FBA14286EE574B92FA0A")
      expect(pseudoheaders_part.body.to_s).to include('Sig: Good signature from 4286EE574B92FA0A abcde <abcde@example.org>')
    ensure
      FileUtils.remove_entry(tmp_gnupg_home)
    end
  end

  context('.key_auto_import_from_attachments') do
    it('successfully validates a signature, whose previously unknown key is attached') do
      list = create(:list, send_encrypted_only: false, key_auto_import_from_email: true)
      list.subscribe('me@localhost', nil, true)
      tmp_gnupg_home = Dir.mktmpdir
      ENV['GNUPGHOME'] = tmp_gnupg_home
      gpg = GPGME::Ctx.new
      gpg.keyimport(File.read('spec/fixtures/openpgp-keys/FB18AE292FCEEBCE3BB3FBA14286EE574B92FA0A-abcde_example_org.sec'))
      keyblock = gpg.find_keys('FB18AE292FCEEBCE3BB3FBA14286EE574B92FA0A').first.export(armor: true).read
      mail = Mail.new
      mail.from = 'abcde@example.org'
      mail.body = 'something'
      mail.to = list.email
      mail.add_file({filename: 'abcde.asc', content: keyblock, mime_type: 'application/pgp-keys'})
      mail.gpg({
        encrypt: false,
        sign: true,
        sign_as: 'FB18AE292FCEEBCE3BB3FBA14286EE574B92FA0A'
      })
      mail.deliver

      expect(list.keys('FB18AE292FCEEBCE3BB3FBA14286EE574B92FA0A').size).to eql(0)

      signed_email = Mail::TestMailer.deliveries.first
      Mail::TestMailer.deliveries.clear
      Schleuder::Runner.new.run(signed_email.to_s, list.email)
      mail_to_subscriber = Mail::TestMailer.deliveries.first

      pseudoheaders_part = mail_to_subscriber.parts.first.parts.first
      expect(list.keys('FB18AE292FCEEBCE3BB3FBA14286EE574B92FA0A').size).to eql(1)
      expect(pseudoheaders_part.body.to_s).to include("Note: This key was newly added from this email:\n  0xFB18AE292FCEEBCE3BB3FBA14286EE574B92FA0A")
      expect(pseudoheaders_part.body.to_s).to include('Sig: Good signature from 4286EE574B92FA0A abcde <abcde@example.org>')
    ensure
      FileUtils.remove_entry(tmp_gnupg_home)
    end

    it('successfully validates a signature, whose previously unknown key is attached, from an encrypted+signed message') do
      list = create(:list, send_encrypted_only: false, key_auto_import_from_email: true)
      list.subscribe('me@localhost', nil, true)
      list_key = list.key.export
      tmp_gnupg_home = Dir.mktmpdir
      ENV['GNUPGHOME'] = tmp_gnupg_home
      gpg = GPGME::Ctx.new
      gpg.keyimport(File.read('spec/fixtures/openpgp-keys/FB18AE292FCEEBCE3BB3FBA14286EE574B92FA0A-abcde_example_org.sec'))
      mail = Mail.new
      mail.from = 'abcde@example.org'
      mail.body = 'something'
      mail.to = list.email
      keyblock = gpg.find_keys('FB18AE292FCEEBCE3BB3FBA14286EE574B92FA0A').first.export(armor: true).read
      mail.add_file({filename: 'abcde.asc', content: keyblock, mime_type: 'application/pgp-keys'})
      gpg.keyimport(list_key)
      mail.gpg({
        encrypt: true,
        keys: {list.email => list.fingerprint},
        sign: true,
        sign_as: 'FB18AE292FCEEBCE3BB3FBA14286EE574B92FA0A'
      })
      mail.deliver

      ENV['GNUPGHOME'] = list.listdir
      expect(list.keys('FB18AE292FCEEBCE3BB3FBA14286EE574B92FA0A').size).to eql(0)

      signed_email = Mail::TestMailer.deliveries.first
      Mail::TestMailer.deliveries.clear
      Schleuder::Runner.new.run(signed_email.to_s, list.email)
      mail_to_subscriber = Mail::TestMailer.deliveries.first

      pseudoheaders_part = mail_to_subscriber.parts.first.parts.first
      expect(list.keys('FB18AE292FCEEBCE3BB3FBA14286EE574B92FA0A').size).to eql(1)
      expect(pseudoheaders_part.body.to_s).to include("Note: This key was newly added from this email:\n  0xFB18AE292FCEEBCE3BB3FBA14286EE574B92FA0A")
      expect(pseudoheaders_part.body.to_s).to include('Enc: Encrypted')
      expect(pseudoheaders_part.body.to_s).to include('Sig: Good signature from 4286EE574B92FA0A abcde <abcde@example.org>')
    ensure
      FileUtils.remove_entry(tmp_gnupg_home)
    end
  end

end
