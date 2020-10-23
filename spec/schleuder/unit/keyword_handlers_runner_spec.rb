require 'spec_helper'

describe 'KeywordHandlersRunner' do
  it 'stores a keyword that was registered' do
    KeywordHandlersRunner.register_keyword(
      type: :request,
      keyword: 'a_keyword',
      handler_class: Object
    )

    expect(KeywordHandlersRunner::REGISTERED_KEYWORDS[:request]['a-keyword']).to be_a(Class)
  end

  it 'stores a second registered keyword identically to the first' do
    KeywordHandlersRunner.register_keyword(
      type: :request,
      keyword: 'a_keyword',
      handler_class: Object
    )
    KeywordHandlersRunner.register_keyword(
      type: :request,
      keyword: 'another_keyword',
      handler_class: Object
    )

    expect(KeywordHandlersRunner::REGISTERED_KEYWORDS[:request]['a-keyword']).to eql(KeywordHandlersRunner::REGISTERED_KEYWORDS[:request]['another-keyword'])
  end

  it 'requires X-LIST-NAME' do
    mail = Mail.new
    mail.body = 'x-list-keys'
    mail.list = create(:list)
    mail = Mail.create_message_to_list(mail, mail.list.request_address, mail.list)

    output = KeywordHandlersRunner.run(mail: mail, list: create(:list), type: :request)

    expect(output).to eql(['Your message did not contain the required "X-LIST-NAME" keyword and was rejected.'])
  end

  it 'rejects X-LIST-NAME with mismatching argument' do
    mail = Mail.new
    mail.body = 'x-list-name: something'
    mail.list = create(:list)
    mail = Mail.create_message_to_list(mail, mail.list.request_address, mail.list)

    output = KeywordHandlersRunner.run(mail: mail, list: create(:list), type: :request)

    expect(output).to eql([%{Your message contained an incorrect "X-LIST-NAME" keyword. The keyword argument must match the email address of this list.\n\nKind regards,\nYour Schleuder system.\n}])
  end

  it 'rejects unknown keywords' do
    list = create(:list)
    mail = Mail.new
    mail.body = "x-list-subscriptions\nx-blabla\nx-list-name: #{list.email}\n"
    mail.list = create(:list)
    mail = Mail.create_message_to_list(mail, mail.list.request_address, mail.list)

    output = nil
    begin
      output = KeywordHandlersRunner.run(mail: mail, list: list, type: :request)
    rescue => exc
    end

    expect(output).to eql(nil)
    expect(exc.class).to eql(Schleuder::Errors::UnknownKeyword)
  end

  it 'does not require mandatory keywords if no keywords are present' do
    output = KeywordHandlersRunner.run(mail: Mail.new, list: create(:list), type: :request)
    expect(output).to eql([])
  end

  it 'loads additional keyword handlers' do
    mail = Mail.new
    mail.list = create(:list)
    mail.list.subscribe('subscription@example.net', 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE', false)
    mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
    mail.body = "x-custom-keyword\nx-list-name: #{mail.list.email}"
    mail = Mail.create_message_to_list(mail, mail.list.request_address, mail.list)
    # Pretend that the message was signed.
    mail.instance_variable_set('@signing_key', mail.list.key('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE'))

    output = KeywordHandlersRunner.run(mail: mail, list: mail.list, type: :request)

    expect(Schleuder::KeywordHandlers::CustomKeyword.ancestors).to include(Schleuder::KeywordHandlers::Base)
    expect(output).to eql(['Something something'])
  end

  it 'notifies admins' do
    mail = Mail.new
    mail.list = create(:list, keywords_admin_notify: ['list-subscriptions'])
    mail.list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
    mail.body = "x-list-subscriptions\nx-list-name: #{mail.list.email}\n"
    mail = Mail.create_message_to_list(mail, mail.list.request_address, mail.list)
    # Pretend that the message was signed.
    mail.instance_variable_set('@signing_key', mail.list.key('59C71FB38AEE22E091C78259D06350440F759BD3'))

    output = KeywordHandlersRunner.run(mail: mail, list: mail.list, type: :request)
    raw = Mail::TestMailer.deliveries.first
    message = Mail.create_message_to_list(raw.to_s, mail.list.request_address, mail.list).setup
    wanted_response = "Subscriptions:\n\nschleuder@example.org\t0x59C71FB38AEE22E091C78259D06350440F759BD3"

    expect(output).to eql([wanted_response])
    expect(Mail::TestMailer.deliveries.count).to be(1)
    expect(message.to).to eql(['schleuder@example.org'])
    expect(message.subject).to eql('Notice')
    expect(message.first_plaintext_part.body.to_s).to include('list-subscriptions: ')
    expect(message.first_plaintext_part.body.to_s).to include(wanted_response)
  end

  it 'returns an error message if keyword is not permitted for subscribers' do
    mail = Mail.new
    mail.list = create(:list, subscriber_permissions: {
                  'view-subscriptions' => false,
                })
    mail.list.subscribe('subscription@example.org', 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE', false)
    mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
    mail.body = "x-list-subscriptions\nx-list-name: #{mail.list.email}\n"
    mail = Mail.create_message_to_list(mail, mail.list.request_address, mail.list)
    # Pretend that the message was signed.
    mail.instance_variable_set('@signing_key', mail.list.key('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE'))

    output = KeywordHandlersRunner.run(mail: mail, list: mail.list, type: :request)

    expect(output).to eql(["The keyword 'list-subscriptions' may for this list only be used by admins."])
    expect(Mail::TestMailer.deliveries.count).to be(0)
  end
end
