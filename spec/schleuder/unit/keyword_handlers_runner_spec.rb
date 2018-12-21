require 'spec_helper'

describe 'KeywordHandlersRunner' do
  it 'stores a keyword that was registered' do
    KeywordHandlersRunner.register_keyword(
      type: :request,
      keyword: 'a-keyword',
      handler_class: Object,
      handler_method: 'a_method',
      aliases: 'an-alias'
    )

    expect(KeywordHandlersRunner::REGISTERED_KEYWORDS[:request]['a-keyword']).to be_a(Hash)
    expect(KeywordHandlersRunner::REGISTERED_KEYWORDS[:request]['an-alias']).to eql(KeywordHandlersRunner::REGISTERED_KEYWORDS[:request]['a-keyword'])
  end

  it 'requires X-LIST-NAME' do
    mail = Mail.new
    mail.body = 'x-list-keys'
    mail.to_s

    output = KeywordHandlersRunner.run(mail: mail, list: create(:list), type: :request)

    expect(output).to eql(['Your message did not contain the required "X-LIST-NAME" keyword and was rejected.'])
  end

  it 'rejects X-LIST-NAME with mismatching argument' do
    mail = Mail.new
    mail.body = 'x-list-name: something'
    mail.to_s

    output = KeywordHandlersRunner.run(mail: mail, list: create(:list), type: :request)

    expect(output).to eql(['Your message contained an incorrect "X-LIST-NAME" keyword. The keyword argument must match the email address of this list.'])
  end

  it 'requires X-STOP' do
    list = create(:list)
    mail = Mail.new
    mail.body = "x-list-keys\nx-list-name: #{list.email}"
    mail.to_s

    output = KeywordHandlersRunner.run(mail: mail, list: list, type: :request)

    expect(output).to eql(["Your message lacked the keyword 'X-STOP'. If you use keywords in a message, you must indicate with 'X-STOP' where to stop looking for further keywords."])
  end

  it 'rejects unknown keywords' do
    list = create(:list)
    mail = Mail.new
    mail.body = "x-list-subscriptions\nx-blabla\nx-list-name: #{list.email}\nx-stop"
    mail.to_s

    output = KeywordHandlersRunner.run(mail: mail, list: list, type: :request)

    expect(output).to eql(["The given keyword 'blabla' is unknown. Please check its spelling or the documentation."])
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
    mail.instance_variable_set('@signing_key', mail.list.key('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE'))
    mail.body = "x-custom-keyword\nx-list-name: #{mail.list.email}\nx-stop"
    mail.to_s

    output = KeywordHandlersRunner.run(mail: mail, list: mail.list, type: :request)

    expect(CustomKeyword.ancestors).to include(Schleuder::KeywordHandlers::Base)
    expect(output).to eql(['Something something'])
  end

  it 'notifies admins' do
    mail = Mail.new
    mail.list = create(:list, keywords_admin_notify: ['list-subscriptions'])
    mail.list.subscribe('schleuder@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
    mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
    mail.instance_variable_set('@signing_key', mail.list.key('59C71FB38AEE22E091C78259D06350440F759BD3'))
    mail.body = "x-list-subscriptions\nx-list-name: #{mail.list.email}\nx-stop"
    mail.to_s

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
    mail.list.subscribe('subscription@example.org', '59C71FB38AEE22E091C78259D06350440F759BD3', false)
    mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
    mail.instance_variable_set('@signing_key', mail.list.key('59C71FB38AEE22E091C78259D06350440F759BD3'))
    mail.body = "x-list-subscriptions\nx-list-name: #{mail.list.email}\nx-stop"
    mail.to_s

    output = KeywordHandlersRunner.run(mail: mail, list: mail.list, type: :request)

    expect(output).to eql(["Unfortunately you are not allowed to do that.\n\nIf you need help please contact\nyour list-admins <#{mail.list.owner_address}>\nor read the documentation <https://schleuder.org/schleuder/docs/>.\n\n\nKind regards,\nYour Schleuder system.\n"])
    expect(Mail::TestMailer.deliveries.count).to be(0)
  end
end
