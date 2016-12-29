require "spec_helper"

describe "user sends an encrypted message" do
  it "from thunderbird" do
    start_smtp_daemon
    list = create(:list)
    list.subscribe("admin@example.org", nil, true)
    message_path = 'spec/fixtures/mails/encrypted-mime/thunderbird.eml'

    error = run_schleuder(:work, list.email, message_path)
    mails = Dir.glob("#{smtp_daemon_outputdir}/mail-*")

    expect(error).to be_empty
    expect(mails.size).to eq 1

    stop_smtp_daemon
  end
end

