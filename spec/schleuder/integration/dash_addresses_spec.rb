require "spec_helper"

describe 'someone sends an email to a listname-dash-address' do
  it "sends the list's key as reply to -sendkey" do
    list = create(:list)
    list.subscribe("schleuder@example.org", nil, true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.sendkey_address
    mail.from = 'outside@example.org'
    mail.body = 'The key, please!'
    mail.subject = 'key'
    mail.deliver

    mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear
    output = nil
    begin
      output = Schleuder::Runner.new().run(mail.to_s, list.sendkey_address)
    rescue SystemExit
    end

    # if properly exited there was no output
    expect(output).to be_nil

    raw = Mail::TestMailer.deliveries.first
    message = raw.setup(list.email, list)

    expect(message.to).to eql(['outside@example.org'])
    expect(message.parts.first.body.to_s).to eql('Find the key for this address attached.')
    expect(message.attachments.first.body.to_s).to include(list.fingerprint)
    expect(message.attachments.first.body.to_s).to include('-----BEGIN PGP PUBLIC KEY BLOCK-----')
    expect(message.in_reply_to).to eql(mail.message_id)
  end

  it "forwards the message to the admins if extension is -owner" do
    list = create(:list)
    list.subscribe("schleuder@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    list.subscribe("admin@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.owner_address
    mail.from = 'outside@example.org'
    mail.body = 'Please contact me directly!'
    mail.subject = 'help'
    mail.deliver

    mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear
    output = nil
    begin
      output = Schleuder::Runner.new().run(mail.to_s, list.owner_address)
    rescue SystemExit
    end

    # if properly exited there was no output
    expect(output).to be_nil

    raw_msgs = Mail::TestMailer.deliveries
    raw_msgs.sort_by { |msg| msg.to.first }
    message1 = raw_msgs[0].setup(list.email, list)
    message2 = raw_msgs[1].setup(list.email, list)

    expect(message1.to).to eql(['admin@example.org'])
    expect(message1.subject).to eql('help')
    expect(message1.parts.first.body.to_s).to include('From: outside@example.org')
    expect(message1.parts.first.body.to_s).to include('Note: The following message was received for the list-owners.')
    expect(message1.parts.last.body.to_s).to eql('Please contact me directly!')

    expect(message2.to).to eql(['schleuder@example.org'])
    expect(message2.subject).to eql('help')
    expect(message2.parts.first.body.to_s).to include('From: outside@example.org')
    expect(message2.parts.first.body.to_s).to include('Note: The following message was received for the list-owners.')
    expect(message2.parts.last.body.to_s).to eql('Please contact me directly!')
  end

  it "forwards the message to the admins if extension is -bounce" do
    list = create(:list)
    list.subscribe("admin@example.org", '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    ENV['GNUPGHOME'] = list.listdir
    mail = Mail.new
    mail.to = list.bounce_address
    mail.from = 'mailer-daemon@example.org'
    mail.body = 'delivery failure'
    mail.subject = 'something'
    mail.deliver

    mail = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear
    output = nil
    begin
      output = Schleuder::Runner.new().run(mail.to_s, list.bounce_address).inspect
    rescue SystemExit
    end

    # if properly exited there was no output
    expect(output).to be_nil

    raw_msg = Mail::TestMailer.deliveries.first
    message = raw_msg.setup(list.email, list)

    expect(message.to).to eql(['admin@example.org'])
    expect(message.subject).to eql(I18n.t('automated_message_subject'))
    expect(message.parts.first.body.to_s).to eql(I18n.t('forward_automated_message_to_admins'))
    expect(message.parts.last.mime_type).to eql('message/rfc822')
    expect(message.parts.last.body.to_s).to include('From: mailer-daemon@example.org')
    expect(message.parts.last.body.to_s).to include(mail.message_id)
    expect(message.parts.last.body.to_s).to include("Subject: something")
    expect(message.parts.last.body.to_s).to include("delivery failure")
  end
end

