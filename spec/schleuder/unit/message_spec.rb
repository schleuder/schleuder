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
    mail = mail.setup('something-bounce@localhost', list)

    expect(mail.automated_message?).to be(true)
  end

  it "recognizes a message with 'Auto-Submitted'-header as automated message" do
    list = create(:list)
    mail = Mail.new
    mail.header['Auto-Submitted'] = 'yes'
    mail = mail.setup('something@localhost', list)

    expect(mail.automated_message?).to be(true)
  end

  it "recognizes a cron message with 'Auto-Submitted'-header NOT as automated message" do
    list = create(:list)
    mail = Mail.new
    mail.header['Auto-Submitted'] = 'yes'
    mail.header['X-Cron-Env'] = '<MAILTO=root>'
    mail = mail.setup('something@localhost', list)

    expect(mail.automated_message?).to be(false)
  end
end

