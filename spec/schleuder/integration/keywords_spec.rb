require "spec_helper"

describe "user sends keyword" do
  it "x-subscribe without attributes" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
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
    mail.body = "x-listname: #{list.email}\nX-SUBSCRIBE: test@example.org"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = raw.setup(list.request_address, list)
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("test@example.org has been subscribed")
    expect(message.to_s).to match(/Fingerprint:\s*$/)
    expect(message.to_s).to include("Admin? false")
    expect(message.to_s).to include("Email-delivery enabled? true")

    expect(subscription).to be_present
    expect(subscription.fingerprint).to be_blank
    expect(subscription.admin).to eql(false)
    expect(subscription.delivery_enabled).to eql(true)


    teardown_list_and_mailer(list)
  end

  it "x-subscribe with attributes" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
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
    mail.body = "x-listname: #{list.email}\nX-SUBSCRIBE: test@example.org 0x#{list.fingerprint} true false"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = raw.setup(list.request_address, list)
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("test@example.org has been subscribed")
    expect(message.to_s).to match(/Fingerprint:\s+#{list.fingerprint.downcase}/)
    expect(message.to_s).to include("Admin? true")
    expect(message.to_s).to include("Email-delivery enabled? false")

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql(list.fingerprint.downcase)
    expect(subscription.admin).to eql(true)
    expect(subscription.delivery_enabled).to eql(false)

    teardown_list_and_mailer(list)
  end

  it "x-unsubscribe without argument" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    list.subscribe("admin@example.org", 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.request_address
    mail.from = 'schleuder@example.org'
    gpg_opts = {
      encrypt: true,
      keys: {list.request_address => list.fingerprint},
      sign: true,
      sign_as: '59C71FB38AEE22E091C78259D06350440F759BD3'
    }
    mail.gpg(gpg_opts)
    mail.body = "x-listname: #{list.email}\nX-UNSUBSCRIBE:"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = raw.setup(list.request_address, list)

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("schleuder@example.org has been unsubscribed")

    teardown_list_and_mailer(list)
  end

  it "x-unsubscribe with invalid argument" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
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
    mail.body = "x-listname: #{list.email}\nX-UNSUBSCRIBE: test@example.org"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = raw.setup(list.request_address, list)

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("test@example.org is not subscribed")

    teardown_list_and_mailer(list)
  end

  it "x-unsubscribe" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.subscribe("test@example.org")
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
    mail.body = "x-listname: #{list.email}\nX-UNSUBSCRIBE: test@example.org"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = raw.setup(list.request_address, list)
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("test@example.org has been unsubscribed")

    expect(subscription).to be_blank

    teardown_list_and_mailer(list)
  end

  it "x-add-key with inline key-material" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
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
    keymaterial = File.read('spec/fixtures/example_key.txt')
    mail.body = "x-listname: #{list.email}\nX-ADD-KEY:\n#{keymaterial}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = raw.setup(list.request_address, list)

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("C4D60F8833789C7CAA44496FD3FFA6613AB10ECE: imported")

    teardown_list_and_mailer(list)
  end

  it "x-add-key with attached key-material" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
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
    mail.body = "x-listname: #{list.email}\nX-ADD-KEY:"
    mail.add_file('spec/fixtures/example_key.txt')
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = raw.setup(list.request_address, list)

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("C4D60F8833789C7CAA44496FD3FFA6613AB10ECE: imported")

    teardown_list_and_mailer(list)
  end

  it "x-resend" do
    list = create(:list, public_footer: "-- \nblablabla")
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "x-listname: #{list.email}\nX-resend: someone@example.org\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    resent_message = raw.verify
    resent_message_body = resent_message.parts.map { |p| p.body.to_s }.join
    raw = Mail::TestMailer.deliveries.last
    message = raw.setup(list.email, list)

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("Resent: Unencrypted to someone@example.org")
    expect(resent_message.to).to include("someone@example.org")
    expect(resent_message.to_s).not_to include("Resent: Unencrypted to someone@example.org")
    expect(resent_message_body).to eql(content_body + list.public_footer.to_s)

    teardown_list_and_mailer(list)
  end

  it "x-resend without x-listname" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "X-resend: someone@example.org\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = raw.setup(list.email, list)

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).not_to include("Resent: Unencrypted to someone@example.org")
    expect(message.to_s).to include("Your message didn't contain the mandatory X-LISTNAME-keyword, thus it was rejected.")

    teardown_list_and_mailer(list)
  end

  it "x-resend with wrong x-listname" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.email
    mail.from = list.admins.first.email
    gpg_opts = {
      encrypt: true,
      keys: {list.email => list.fingerprint},
      sign: true,
      sign_as: list.admins.first.fingerprint
    }
    mail.gpg(gpg_opts)
    content_body = "Hello again!\n"
    mail.body = "x-listname: somethingelse@example.org\nX-resend: someone@example.org\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = raw.setup(list.email, list)

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).not_to include("Resent: Unencrypted to someone@example.org")
    expect(message.to_s).to include("Your message contained a wrong X-LISTNAME-keyword. The value of that keyword must match the email address of this list.")

    teardown_list_and_mailer(list)
  end

  it "x-sign-this with inline text" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
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
    signed_text = "signed\nsigned\nsigned\n\n"
    mail.body = "x-listname: #{list.email}\nx-sign-this:\n#{signed_text}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = raw.setup(list.email, list)

    expect(message.to_s.gsub("\r", '')).to include("BEGIN PGP SIGNED MESSAGE-----\n\n#{signed_text}-----END PGP SIGNED MESSAGE")

    teardown_list_and_mailer(list)
  end

  it "x-sign-this with attachments" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
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
    signed_content = File.read('spec/fixtures/example_key.txt')
    mail.attachments['example_key.txt'] = { mime_type: 'application/pgp-key',
                                            content: signed_content }
    mail.body = "\n\nx-listname: #{list.email}\nx-sign-this:"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = raw.setup(list.email, list)
    signature = message.attachments.first.body.to_s
    # list.gpg.verify() results in a "Bad Signature".  The sign-this plugin
    # also uses GPGME::Crypto, apparently that makes a difference.
    crypto = GPGME::Crypto.new
    verification_string = ''
    crypto.verify(signature, {signed_text: signed_content}) do |sig|
      verification_string = sig.to_s
    end

    expect(message.to_s).to include("Find the signatures attached.")
    expect(message.attachments.size).to eql(1)
    expect(message.attachments.first.filename).to eql("example_key.txt.sig")
    expect(verification_string).to include("Good signature from D06350440F759BD3")

    teardown_list_and_mailer(list)
  end

  it "x-list-key with arbitrary email-sub-string" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
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
    mail.body = "x-listname: #{list.email}\nX-list-KEYs: der@ex"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = raw.setup(list.request_address, list)

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("pub   4096R/59C71FB38AEE22E091C78259D06350440F759BD3 2016-12-06")
    expect(message.to_s.scan(/^pub /).size).to eql(1)

    teardown_list_and_mailer(list)
  end

  it "x-list-key with correctly prefixed email-sub-string" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
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
    mail.body = "x-listname: #{list.email}\nX-list-KEYs: @schleuder"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = raw.setup(list.request_address, list)

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("pub   4096R/59C71FB38AEE22E091C78259D06350440F759BD3 2016-12-06")
    expect(message.to_s.scan(/^pub /).size).to eql(1)

    teardown_list_and_mailer(list)
  end

  it "x-list-key with prefixed fingerprint" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
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
    mail.body = "x-listname: #{list.email}\nX-list-KEYs: 0x59C71FB38AEE22E091C78259D06350440F759BD3"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = raw.setup(list.request_address, list)

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("pub   4096R/59C71FB38AEE22E091C78259D06350440F759BD3 2016-12-06")
    expect(message.to_s.scan(/^pub /).size).to eql(1)

    teardown_list_and_mailer(list)
  end

end


