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
  
  it "recognizes a message sent to listname-bounce@hostname as automated message" do
    list = create(:list)
    mail = Mail.new
    # Trigger the setting of mandatory headers.
    mail.to_s
    mail = Mail.create_message_to_list(mail.to_s, 'something-bounce@localhost', list).setup

    expect(mail.automated_message?).to be(true)
  end

  it "recognizes a message with 'Auto-Submitted'-header as automated message" do
    list = create(:list)
    mail = Mail.new
    mail.header['Auto-Submitted'] = 'yes'
    # Trigger the setting of mandatory headers.
    mail.to_s
    mail = Mail.create_message_to_list(mail.to_s, 'something@localhost', list).setup

    expect(mail.automated_message?).to be(true)
  end

  it "recognizes a cron message with 'Auto-Submitted'-header NOT as automated message" do
    list = create(:list)
    mail = Mail.new
    mail.header['Auto-Submitted'] = 'yes'
    mail.header['X-Cron-Env'] = '<MAILTO=root>'
    # Trigger the setting of mandatory headers.
    mail.to_s
    mail = Mail.create_message_to_list(mail.to_s, 'something@localhost', list).setup

    expect(mail.automated_message?).to be(false)
  end

  context '#add_subject_prefix!' do
    it 'adds a configured subject prefix' do
      list = create(:list)
      list.subject_prefix = '[prefix]'
      list.subscribe('admin@example.org',nil,true)
      mail = Mail.new
      mail.from 'someone@example.org'
      mail.to list.email
      mail.text_part = 'blabla'
      mail.subject = 'test'

      message = Mail.create_message_to_list(mail.to_s, list.email, list).setup
      message.add_subject_prefix!

      expect(message.subject).to eql('[prefix] test')
    end
    it 'adds a configured subject prefix without subject' do
      list = create(:list)
      list.subject_prefix = '[prefix]'
      list.subscribe('admin@example.org',nil,true)
      mail = Mail.new
      mail.from 'someone@example.org'
      mail.to list.email
      mail.text_part = 'blabla'

      message = Mail.create_message_to_list(mail.to_s, list.email, list).setup
      message.add_subject_prefix!

      expect(message.subject).to eql('[prefix]')
    end
    it 'does not add a subject prefix if already present' do
      list = create(:list)
      list.subject_prefix = '[prefix]'
      list.subscribe('admin@example.org',nil,true)
      mail = Mail.new
      mail.from 'someone@example.org'
      mail.to list.email
      mail.text_part = 'blabla'
      mail.subject = 'Re: [prefix] test'

      message = Mail.create_message_to_list(mail.to_s, list.email, list).setup
      message.add_subject_prefix!

      expect(message.subject).to eql('Re: [prefix] test')
    end
  end
end
