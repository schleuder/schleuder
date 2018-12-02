require 'spec_helper'

describe 'user sends a plain text message' do
  [
    'plain',
    'signed-inline',
    'signed-mime',
  ].each do |t|
    it "from thunderbird being #{t}" do
      start_smtp_daemon
      list = create(:list)
      list.subscribe('admin@example.org', nil, true)
      message_path = "spec/fixtures/mails/#{t}/thunderbird.eml"

      error = run_schleuder(:work, list.email, message_path)
      mails = Dir.glob("#{smtp_daemon_outputdir}/mail-*")

      expect(error).to be_empty
      expect(mails.size).to eq 1

      stop_smtp_daemon
    end
  end
end

