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
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
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
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
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

  it "x-subscribe with one attribute and spaces-separated fingerprint" do
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
    mail.body = "x-listname: #{list.email}\nX-SUBSCRIBE: test@example.org 0x#{list.fingerprint.dup.insert(4, ' ')} true"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("test@example.org has been subscribed")
    expect(message.to_s).to match(/Fingerprint:\s+#{list.fingerprint.downcase}/)
    expect(message.to_s).to include("Admin? true")
    expect(message.to_s).to include("Email-delivery enabled? true")

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql(list.fingerprint.downcase)
    expect(subscription.admin).to eql(true)
    expect(subscription.delivery_enabled).to eql(true)

    teardown_list_and_mailer(list)
  end


  it "x-subscribe without attributes, but with spaces-separated fingerprint" do
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
    mail.body = "x-listname: #{list.email}\nX-SUBSCRIBE: test@example.org 0x#{list.fingerprint.dup.insert(4, ' ')}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("test@example.org has been subscribed")
    expect(message.to_s).to match(/Fingerprint:\s+#{list.fingerprint.downcase}/)
    expect(message.to_s).to include("Admin? false")
    expect(message.to_s).to include("Email-delivery enabled? true")

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql(list.fingerprint.downcase)
    expect(subscription.admin).to eql(false)
    expect(subscription.delivery_enabled).to eql(true)

    teardown_list_and_mailer(list)
  end

  it "x-subscribe with attributes and spaces-separated fingerprint" do
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
    mail.body = "x-listname: #{list.email}\nX-SUBSCRIBE: test@example.org 0x#{list.fingerprint.dup.insert(4, ' ')} true false"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
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
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("schleuder@example.org has been unsubscribed")

    expect(subscription).to be_blank

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
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

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
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("test@example.org has been unsubscribed")

    expect(subscription).to be_blank

    teardown_list_and_mailer(list)
  end

  it "x-set-fingerprint with own email-address and valid fingerprint" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
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
    mail.body = "x-listname: #{list.email}\nX-set-fingerprint: schleuder@example.org C4D60F8833789C7CAA44496FD3FFA6613AB10ECE"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'schleuder@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("Fingerprint for schleuder@example.org set to c4d60f8833789c7caa44496fd3ffa6613ab10ece")

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql('c4d60f8833789c7caa44496fd3ffa6613ab10ece')

    teardown_list_and_mailer(list)
  end


  it "x-set-fingerprint with own email-address and valid, spaces-separated fingerprint" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
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
    mail.body = "x-listname: #{list.email}\nX-set-fingerprint: schleuder@example.org C4D6 0F88 3378 9C7C  AA44 496F D3FF A661 3AB1 0ECE"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'schleuder@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("Fingerprint for schleuder@example.org set to c4d60f8833789c7caa44496fd3ffa6613ab10ece")

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql('c4d60f8833789c7caa44496fd3ffa6613ab10ece')

    teardown_list_and_mailer(list)
  end


  it "x-set-fingerprint without email-address and with valid fingerprint" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
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
    mail.body = "x-listname: #{list.email}\nX-set-fingerprint: C4D60F8833789C7CAA44496FD3FFA6613AB10ECE"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'schleuder@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("Fingerprint for schleuder@example.org set to c4d60f8833789c7caa44496fd3ffa6613ab10ece")

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql('c4d60f8833789c7caa44496fd3ffa6613ab10ece')

    teardown_list_and_mailer(list)
  end

  it "x-set-fingerprint with other email-address and valid fingerprint" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.subscribe('test@example.org')
    list.import_key(File.read('spec/fixtures/example_key.txt'))
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
    mail.body = "x-listname: #{list.email}\nX-set-fingerprint: test@example.org C4D60F8833789C7CAA44496FD3FFA6613AB10ECE"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("Fingerprint for test@example.org set to c4d60f8833789c7caa44496fd3ffa6613ab10ece")

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql('c4d60f8833789c7caa44496fd3ffa6613ab10ece')

    teardown_list_and_mailer(list)
  end

  it "x-set-fingerprint with other email-address and valid fingerprint as non-admin" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3')
    list.subscribe("test@example.org", 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
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
    mail.body = "x-listname: #{list.email}\nX-set-fingerprint: test@example.org 59C71FB38AEE22E091C78259D06350440F759BD3"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'test@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("Only admins may set fingerprints of subscriptions other than their own")

    expect(subscription).to be_present
    expect(subscription.fingerprint).to eql('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')

    teardown_list_and_mailer(list)
  end

  it "x-set-fingerprint without email-address and with invalid fingerprint" do
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
    mail.body = "x-listname: #{list.email}\nX-set-fingerprint: blabla"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    subscription = list.subscriptions.where(email: 'schleuder@example.org').first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("Fingerprint is not a valid OpenPGP-fingerprint")

    expect(subscription.fingerprint).to eql('59C71FB38AEE22E091C78259D06350440F759BD3')

    teardown_list_and_mailer(list)
  end

  it "x-set-fingerprint with not-subscribed email-address and valid fingerprint" do
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
    mail.body = "x-listname: #{list.email}\nX-set-fingerprint: bla@example.org C4D60F8833789C7CAA44496FD3FFA6613AB10ECE"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("bla@example.org is not subscribed")

    teardown_list_and_mailer(list)
  end

  it "x-list-subscriptions without arguments" do
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
    mail.body = "x-listname: #{list.email}\nX-list-subscriptions:"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s.lines.size).to eql(3)
    expect(message.to_s).to include("schleuder@example.org	0x59C71FB38AEE22E091C78259D06350440F759BD3")

    teardown_list_and_mailer(list)
  end

  it "x-list-subscriptions without arguments but with admin-notification" do
    list = create(:list, keywords_admin_notify: ['list-subscriptions'])
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.subscribe("user@example.org")
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
    mail.body = "x-listname: #{list.email}\nX-list-subscriptions:"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    notification = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    raw = Mail::TestMailer.deliveries[1]
    response = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup
    expected_text = "Subscriptions:\n\nschleuder@example.org\t0x59C71FB38AEE22E091C78259D06350440F759BD3\nuser@example.org"

    expect(Mail::TestMailer.deliveries.size).to eql(2)
    expect(notification.to).to eql(['schleuder@example.org'])
    expect(notification.first_plaintext_part.body.to_s).to eql("schleuder@example.org sent the keyword 'list-subscriptions' and received this response:\n\n#{expected_text}")

    expect(response.to).to eql(['schleuder@example.org'])
    expect(response.first_plaintext_part.body.to_s).to eql(expected_text)

    teardown_list_and_mailer(list)
  end

  it "x-list-subscriptions with matching argument" do
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
    mail.body = "x-listname: #{list.email}\nX-list-subscriptions: example.org"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s.lines.size).to eql(3)
    expect(message.to_s).to include("schleuder@example.org	0x59C71FB38AEE22E091C78259D06350440F759BD3")

    teardown_list_and_mailer(list)
  end

  it "x-list-subscriptions with non-matching argument" do
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
    mail.body = "x-listname: #{list.email}\nX-list-subscriptions: blabla"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s.lines.size).to eql(1)
    expect(message.to_s).to include("Your message resulted in no output")

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
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

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
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("C4D60F8833789C7CAA44496FD3FFA6613AB10ECE: imported")

    teardown_list_and_mailer(list)
  end

  it "x-fetch-key with invalid input" do
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
    mail.body = "x-listname: #{list.email}\nX-fetch-KEY: lala!"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to_s).to include("Invalid input.")

    teardown_list_and_mailer(list)
  end

  it "x-fetch-key with email address" do
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
    mail.body = "x-listname: #{list.email}\nX-fetch-KEY: admin@example.org"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    with_sks_mock do
      begin
        Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
      rescue SystemExit
      end
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to_s).to include("Key 98769E8A1091F36BD88403ECF71A3F8412D83889 was fetched (new key)")

    teardown_list_and_mailer(list)
  end

  it "x-fetch-key with unknown email-address" do
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
    mail.body = "x-listname: #{list.email}\nX-fetch-KEY: something@localhost"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    with_sks_mock do
      begin
        Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
      rescue SystemExit
      end
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to_s).to include("Fetching something@localhost did not succeed")

    teardown_list_and_mailer(list)
  end

  it "x-fetch-key with URL" do
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
    mail.body = "x-listname: #{list.email}\nX-fetch-KEY: http://127.0.0.1:9999/keys/example.asc"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    with_sks_mock do
      begin
        Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
      rescue SystemExit
      end
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to_s).to include("Key 98769E8A1091F36BD88403ECF71A3F8412D83889 was fetched (new key)")

    teardown_list_and_mailer(list)
  end

  it "x-fetch-key with invalid URL" do
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
    url = "http://127.0.0.1:9999/foo"
    mail.body = "x-listname: #{list.email}\nX-fetch-KEY: #{url}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    with_sks_mock do
      begin
        Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
      rescue SystemExit
      end
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to_s).to include("Fetching #{url} did not succeed")

    teardown_list_and_mailer(list)
  end

  it "x-fetch-key with unknown fingerprint" do
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
    mail.body = "x-listname: #{list.email}\nX-fetch-KEY: 0x0000000000000000000000000000000000000000"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    with_sks_mock do
      begin
        Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
      rescue SystemExit
      end
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to_s).to include("Fetching 0x0000000000000000000000000000000000000000 did not succeed")

    teardown_list_and_mailer(list)
  end

  it "x-fetch-key with fingerprint" do
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
    mail.body = "x-listname: #{list.email}\nX-fetch-KEY: 0x98769E8A1091F36BD88403ECF71A3F8412D83889"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    with_sks_mock do
      begin
        Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
      rescue SystemExit
      end
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to_s).to include("Key 98769E8A1091F36BD88403ECF71A3F8412D83889 was fetched (new key)")

    teardown_list_and_mailer(list)
  end

  it "x-fetch-key with fingerprint of unchanged key" do
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
    mail.body = "x-listname: #{list.email}\nX-fetch-KEY: 0x59C71FB38AEE22E091C78259D06350440F759BD3"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    with_sks_mock do
      begin
        Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
      rescue SystemExit
      end
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.first_plaintext_part.body.to_s).to eql("Key 59C71FB38AEE22E091C78259D06350440F759BD3 was fetched (unchanged).")

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
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("Resent: Unencrypted to someone@example.org")
    expect(resent_message.to).to include("someone@example.org")
    expect(resent_message.to_s).not_to include("Resent: Unencrypted to someone@example.org")
    expect(resent_message_body).to eql(content_body + list.public_footer.to_s)

    teardown_list_and_mailer(list)
  end

  it "x-resend with admin-notification" do
    list = create(:list, keywords_admin_notify: ['resend'])
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
    raw = Mail::TestMailer.deliveries[1]
    notification = Mail.create_message_to_list(raw.to_s, list.email, list).setup
    raw = Mail::TestMailer.deliveries[2]
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(Mail::TestMailer.deliveries.size).to eql(3)

    expect(notification.to).to eql(['schleuder@example.org'])
    expect(notification.first_plaintext_part.body.to_s).to eql("schleuder@example.org used the keyword 'resend' with the values 'someone@example.org' in a message sent to the list.")

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("Resent: Unencrypted to someone@example.org")

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
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).not_to include("Resent: Unencrypted to someone@example.org")
    expect(message.to_s).to include("Your message didn't contain the mandatory X-LISTNAME-keyword, thus it was rejected.")

    teardown_list_and_mailer(list)
  end

  it "x-resend with two matching keys, one of which is expired" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    list.import_key(File.read("spec/fixtures/expired_key.txt"))
    list.import_key(File.read("spec/fixtures/bla_foo_key.txt"))
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
    mail.body = "x-listname: #{list.email}\nX-resend-encrypted-only: bla@foo\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    resent_message = Mail::TestMailer.deliveries.first
    raw = Mail::TestMailer.deliveries.last
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(list.keys('bla@foo').size).to eql(2)
    expect(resent_message.to).to eql(['bla@foo'])
    expect(resent_message.content_type).to match(/^multipart\/encrypted.*application\/pgp-encrypted/)
    expect(message.first_plaintext_part.body.to_s).to include("Resent: Encrypted to bla@foo (87E65ED2081AE3D16BE4F0A5EBDBE899251F2412)")

    teardown_list_and_mailer(list)
  end

  it "x-resend with expired key" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    list.import_key(File.read("spec/fixtures/expired_key.txt"))
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
    mail.body = "x-listname: #{list.email}\nX-resend-encrypted-only: bla@foo\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(list.keys('bla@foo').size).to eql(1)
    expect(message.first_plaintext_part.to_s).to include("Resending to <bla@foo> failed (0 keys found")

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
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

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
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

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
    keywords = Mail::Part.new
    keywords.body = "\n\nx-listname: #{list.email}\nx-sign-this:"
    mail.parts << keywords
    signed_content = File.read('spec/fixtures/example_key.txt')
    mail.attachments['example_key.txt'] = { mime_type: 'application/pgp-key',
                                            content: signed_content }
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup
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
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

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
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

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
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("pub   4096R/59C71FB38AEE22E091C78259D06350440F759BD3 2016-12-06")
    expect(message.to_s.scan(/^pub /).size).to eql(1)

    teardown_list_and_mailer(list)
  end


  it "x-get-key with valid argument" do
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
    mail.body = "x-listname: #{list.email}\nX-GET-KEY: 0x59C71FB38AEE22E091C78259D06350440F759BD3"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("pub   4096R/59C71FB38AEE22E091C78259D06350440F759BD3 2016-12-06")
    expect(message.to_s).to include("-----BEGIN PGP PUBLIC KEY")

    teardown_list_and_mailer(list)
  end

  it "x-get-key with invalid argument" do
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
    mail.body = "x-listname: #{list.email}\nX-get-KEY: blabla"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("No match found for")
    expect(message.to_s).not_to include("-----BEGIN PGP PUBLIC KEY")

    teardown_list_and_mailer(list)
  end

  it "x-get-key with empty argument" do
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
    mail.body = "x-listname: #{list.email}\nX-get-KEY:"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("Your message resulted in no output")
    expect(message.to_s).not_to include("-----BEGIN PGP PUBLIC KEY")

    teardown_list_and_mailer(list)
  end

  it "x-delete-key with valid argument" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
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
    mail.body = "x-listname: #{list.email}\nX-delete-KEY: C4D60F8833789C7CAA44496FD3FFA6613AB10ECE"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("Deleted: C4D60F8833789C7CAA44496FD3FFA6613AB10ECE")

    teardown_list_and_mailer(list)
  end

  it "x-delete-key with invalid argument" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
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
    mail.body = "x-listname: #{list.email}\nX-delete-KEY: lala"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("No match found for")
    expect(message.to_s).not_to include("Deleted")

    teardown_list_and_mailer(list)
  end

  it "x-delete-key with not distinctly matching argument" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.import_key(File.read('spec/fixtures/example_key.txt'))
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
    mail.body = "x-listname: #{list.email}\nX-delete-KEY: schleuder"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.to_s).to include("Too many matching keys for ")
    expect(message.to_s).not_to include("Deleted")

    teardown_list_and_mailer(list)
  end

  it "x-get-logfile with debug level sends non-empty logfile" do
    list = create(:list)
    list.update_attribute(:log_level, 'debug')
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
    mail.body = "x-listname: #{list.email}\nX-get-logfile"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.parts.last.body.to_s.lines.size).to be > 1
    expect(message.parts.last.body.to_s).to include("Logfile created on")
    expect(message.parts.last.body.to_s).to include("DEBUG")

    teardown_list_and_mailer(list)
  end

  it "x-get-logfile with error-level sends empty logfile" do
    list = create(:list)
    list.update_attribute(:log_level, 'error')
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
    mail.body = "x-listname: #{list.email}\nX-get-logfile"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s.lines.size).to eql(1)
    expect(message.body.to_s).to include("Logfile created on")

    teardown_list_and_mailer(list)
  end

  it "x-attach-listkey" do
    list = create(:list, log_level: 'debug')
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
    content_body = "something something list-key"
    mail.body = "x-listname: #{list.email}\nX-attach-listkey\n#{content_body}"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.email)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.email, list).setup

    expect(message.parts.length).to eql(2)
    expect(message.parts.last.parts.length).to eql(2)
    expect(message.parts.last.parts.first.body.to_s).to eql(content_body)
    expect(message.parts.last.parts.last.content_type.to_s).to eql("application/pgp-keys")
    expect(message.parts.last.parts.last.body.decoded).to include("pub   4096R/59C71FB38AEE22E091C78259D06350440F759BD3 2016-12-06")
    expect(message.parts.last.parts.last.body.decoded).to include("-----BEGIN PGP PUBLIC KEY BLOCK-----")
    expect(message.parts.last.parts.last.body.decoded).to include("mQINBFhGvz0BEADXbbTWo/PStyTznAo/f1UobY0EiVPNKNERvYua2Pnq8BwOQ5bS")

    teardown_list_and_mailer(list)
  end

  it "x-get-version" do
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
    mail.body = "x-listname: #{list.email}\nX-get-version"
    mail.deliver

    encrypted_mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    begin
      Schleuder::Runner.new().run(encrypted_mail.to_s, list.request_address)
    rescue SystemExit
    end
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, list.request_address, list).setup

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.first_plaintext_part.body.to_s.lines.size).to eql(1)
    expect(message.first_plaintext_part.body.to_s).to eql(Schleuder::VERSION)

    teardown_list_and_mailer(list)
  end

end
