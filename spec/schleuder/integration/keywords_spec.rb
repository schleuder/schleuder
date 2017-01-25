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
    mail.body = 'X-SUBSCRIBE: test@example.org'
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
    expect(message.to_s).to include("test@example.org has been subscribed")
    expect(message.to_s).to match(/Fingerprint:\s*$/)
    expect(message.to_s).to include("Admin? false")
    expect(message.to_s).to include("Email-delivery enabled? true")

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
    mail.body = "X-SUBSCRIBE: test@example.org #{list.fingerprint} true false"
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
    expect(message.to_s).to include("test@example.org has been subscribed")
    expect(message.to_s).to match(/Fingerprint:\s+#{list.fingerprint.downcase}/)
    expect(message.to_s).to include("Admin? true")
    expect(message.to_s).to include("Email-delivery enabled? false")

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
    mail.body = "X-ADD-KEY:\n#{keymaterial}"
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
    mail.body = "X-ADD-KEY:"
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
end



