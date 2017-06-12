require "spec_helper"

describe Mail::Message do
  it "doesn't change the order of mime-parts" do
    text_part = Mail::Part.new
    text_part.body = "This is text"
    image_part = Mail::Part.new
    image_part.content_type = 'image/png'
    image_part.content_disposition = 'attachment; filename=spec.png'
    message = Mail.new
    message.parts << image_part
    message.parts << text_part

    # This triggers the sorting.
    message.to_s

    expect(message.parts.first.mime_type).to eql('image/png')
    expect(message.parts.last.mime_type).to eql('text/plain')
  end

  # TODO: test message with "null" address ("<>") as Return-Path. I couldn't
  # bring Mail to generate such a message, yet.
  
  it "recognizes a message sent to listname-bounce@hostname as automated
  message" do
    list = create(:list)
    mail = Mail.new
    # Trigger the setting of mandatory headers.
    mail.to_s
    mail = mail.setup('something-bounce@localhost', list)

    expect(mail.automated_message?).to be(true)
  end

  it "recognizes a message with 'Auto-Submitted'-header as automated message" do
    list = create(:list)
    mail = Mail.new
    mail.header['Auto-Submitted'] = 'yes'
    # Trigger the setting of mandatory headers.
    mail.to_s
    mail = mail.setup('something@localhost', list)

    expect(mail.automated_message?).to be(true)
  end

  it "recognizes a cron message with 'Auto-Submitted'-header NOT as automated message" do
    list = create(:list)
    mail = Mail.new
    mail.header['Auto-Submitted'] = 'yes'
    mail.header['X-Cron-Env'] = '<MAILTO=root>'
    # Trigger the setting of mandatory headers.
    mail.to_s
    mail = mail.setup('something@localhost', list)

    expect(mail.automated_message?).to be(false)
  end

  it "#setup strips HTML-part from multipart/alternative-message that contains ascii-armored PGP-data" do
    list = create(:list)
    mail = Mail.new
    mail.to = list.email
    mail.from = 'outside@example.org'
    content = encrypt_string(list, "blabla")
    mail.text_part = content
    mail.html_part = "<p>#{content}</p>"
    mail.subject = "test"

    message = mail.setup(list.email, list)

    expect(message[:content_type].content_type).to eql("multipart/mixed")
    expect(message.parts.size).to be(1)
    expect(message.parts.first[:content_type].content_type).to eql("text/plain")
    expect(message.dynamic_pseudoheaders).to include("Note: This message included an alternating HTML-part that contained PGP-data. The HTML-part was removed to enable parsing the message more properly.")
  end

  it "#setup does NOT strip HTML-part from multipart/alternative-message that does NOT contain ascii-armored PGP-data" do
    list = create(:list)
    mail = Mail.new
    mail.to = list.email
    mail.from = 'outside@example.org'
    content = "blabla"
    mail.text_part = content
    mail.html_part = "<p>#{content}</p>"
    mail.subject = "test"

    message = mail.setup(list.email, list)

    expect(message[:content_type].content_type).to eql("multipart/alternative")
    expect(message.parts.size).to be(2)
    expect(message.parts.first[:content_type].content_type).to eql("text/plain")
    expect(message.parts.last[:content_type].content_type).to eql("text/html")
    expect(message.dynamic_pseudoheaders).not_to include("Note: This message included an alternating HTML-part that contained PGP-data. The HTML-part was removed to enable parsing the message more properly.")
  end

end

