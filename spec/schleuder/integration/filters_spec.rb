require "spec_helper"

describe "running filters" do
  it "max_message_size" do
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
    mail.body = '+' * (1024 * list.max_message_size_kb)
    mail.deliver

    big_email = Mail::TestMailer.deliveries.first
    Mail::TestMailer.deliveries.clear

    output = process_mail(big_email.to_s, list.email)
    expect(output.message).to eql(I18n.t('errors.message_too_big', { allowed_size: list.max_message_size_kb }))

    teardown_list_and_mailer(list)
  end
end
