require "spec_helper"

describe Schleuder::Runner do

  describe "#run" do
    it "delivers the incoming message" do
      list = create(:list)
      list.subscribe("admin@example.org", nil, true)
      mail = File.read("spec/fixtures/mails/plain_text")
      FileUtils.mkdir_p(list.listdir)

      error = Schleuder::Runner.new().run(mail, list.email)

      expect(Mail::TestMailer.deliveries.length).to eq 1
      expect(error).to be_blank

      FileUtils.rm_rf(list.listdir)
    end
  end
end
