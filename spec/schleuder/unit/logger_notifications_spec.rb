require "spec_helper"

describe Schleuder::LoggerNotifications do
  it "notifies admins of simple text-message" do
    list = create(:list, send_encrypted_only: false)
    list.subscribe("schleuder@example.org", nil, true)
    list.logger.notify_admin("Something", nil, I18n.t('notice'))

    message = Mail::TestMailer.deliveries.first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.subject).to eql(I18n.t('notice'))
    expect(message.first_plaintext_part.body.to_s).to eql("Something")
  end

  it "notifies admins of multiple text-messages" do
    list = create(:list, send_encrypted_only: false)
    list.subscribe("schleuder@example.org", nil, true)
    list.logger.notify_admin(["Something", "anotherthing"], nil, I18n.t('notice'))

    message = Mail::TestMailer.deliveries.first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.subject).to eql(I18n.t('notice'))
    expect(message.parts.first.parts.first.body.to_s).to eql("Something")
    expect(message.parts.first.parts.last.body.to_s).to eql("anotherthing")
  end

  it "notifies admins of multiple text-messages" do
    list = create(:list, send_encrypted_only: false)
    list.subscribe("schleuder@example.org", nil, true)
    list.logger.notify_admin(["Something", "anotherthing"], nil, I18n.t('notice'))

    message = Mail::TestMailer.deliveries.first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.subject).to eql(I18n.t('notice'))
    expect(message.parts.first.parts.first.body.to_s).to eql("Something")
    expect(message.parts.first.parts.last.body.to_s).to eql("anotherthing")
  end

  it "notifies admins of multiple text-messages and the original message" do
    list = create(:list, send_encrypted_only: false)
    list.subscribe("schleuder@example.org", nil, true)
    mail = Mail.new
    mail.subject = "A subject"
    list.logger.notify_admin(["Something", "anotherthing"], mail.to_s, I18n.t('notice'))

    message = Mail::TestMailer.deliveries.first

    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.subject).to eql(I18n.t('notice'))
    expect(message.parts.first.parts.first.body.to_s).to eql("Something")
    expect(message.parts.first.parts[1].body.to_s).to eql("anotherthing")
    expect(message.parts.first.parts[2].body.to_s).to include("Subject: A subject")
    expect(message.parts.first.parts[2][:content_type].content_type).to eql("message/rfc822")
  end
end
