require "spec_helper"

describe Schleuder::Runner do
  describe "#run" do
    context "with a plain text message" do
      it "delivers the incoming message" do
        list = create(:list, send_encrypted_only: false)
        list.subscribe("admin@example.org", nil, true)
        mail = File.read("spec/fixtures/mails/plain/thunderbird.eml")

        error = Schleuder::Runner.new().run(mail, list.email)

        expect(Mail::TestMailer.deliveries.length).to eq 1
        expect(error).to be_blank

        teardown_list_and_mailer(list)
      end

      it "has the correct headerlines" do
        list = create(:list, send_encrypted_only: false)
        list.subscribe("admin@example.org", nil, true)
        mail = File.read("spec/fixtures/mails/plain/thunderbird.eml")

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first

        expect(message.to).to eq ["admin@example.org"]
        expect(message.header.to_s.scan("admin@example.org").size).to eq 1
        expect(message.from).to eq [list.email]

        teardown_list_and_mailer(list)
      end

      it "doesn't have unwanted headerlines from the original message" do
        list = create(:list, send_encrypted_only: false)
        list.subscribe("admin@example.org", nil, true)
        mail = File.read("spec/fixtures/mails/plain/thunderbird.eml")

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first

        expect(message.to).to eq ["admin@example.org"]
        expect(message.header.to_s.scan("zeromail").size).to eq 0
        expect(message.header.to_s.scan("nna.local").size).to eq 0
        expect(message.header.to_s.scan("80.187.107.60").size).to eq 0
        expect(message.header.to_s.scan("User-Agent:").size).to eq 0

        teardown_list_and_mailer(list)
      end

      it "doesn't leak the Message-Id as configured" do
        list = create(:list, send_encrypted_only: false, keep_msgid: false)
        list.subscribe("admin@example.org", nil, true)
        mail = File.read("spec/fixtures/mails/plain/thunderbird.eml")

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first

        expect(message.header.to_s.scan("8db04406-e2ab-fd06-d4c5-c19b5765c52b@web.de").size).to eq 0

        teardown_list_and_mailer(list)
      end

      it "does keep the Message-Id as configured" do
        list = create(:list, send_encrypted_only: false, keep_msgid: true)
        list.subscribe("admin@example.org", nil, true)
        mail = File.read("spec/fixtures/mails/plain/thunderbird.eml")

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first

        expect(message.header.to_s.scan("8db04406-e2ab-fd06-d4c5-c19b5765c52b@web.de").size).to eq 1

        teardown_list_and_mailer(list)
      end

      it "contains the list headers if include_list_headers is set to true" do
        list = create(
          :list,
          email: "superlist@example.org",
          send_encrypted_only: false,
          include_list_headers: true,
        )
        list.subscribe("admin@example.org", nil, true)
        mail = File.read("spec/fixtures/mails/plain/thunderbird.eml")

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first

        expect(message.header["List-Id"].to_s).to eq "<superlist.example.org>"
        expect(message.header["List-Owner"].to_s).to eq "<mailto:superlist-owner@example.org> (Use list's public key)"
        expect(message.header["List-Help"].to_s).to eq "<https://schleuder.nadir.org/>"

        teardown_list_and_mailer(list)
      end

      it "contains the open pgp header if include_openpgp_header is set to true" do
        list = create(
          :list,
          send_encrypted_only: false,
          include_openpgp_header: true,
        )
        list.subscribe("admin@example.org", nil, true)
        mail = File.read("spec/fixtures/mails/plain/thunderbird.eml")

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first

        expect(message.header["Openpgp"].to_s).to include list.fingerprint

        teardown_list_and_mailer(list)
      end

      it "does not deliver content if send_encrypted_only is set to true" do
        list = create(:list, send_encrypted_only: true)
        list.subscribe("admin@example.org", nil, true)
        mail = File.read("spec/fixtures/mails/plain/thunderbird.eml")

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first

        expect(message.body).to eq ""
        expect(message.parts.first.body.to_s).to include "You missed an email from "\
          "#{list.email} because your subscription isn't associated with a "\
          "(usable) OpenPGP key. Please fix this."

        teardown_list_and_mailer(list)
      end
    end

    it "delivers a signed error message if a subscription's key is expired on a encrypted-only list" do
        list = create(:list, send_encrypted_only: true)
        list.subscribe("admin@example.org", nil, true, false)
        list.subscribe("expired@example.org", '98769E8A1091F36BD88403ECF71A3F8412D83889')
        key = File.read("spec/fixtures/expired_key.txt")
        list.import_key(key)
        mail = File.read("spec/fixtures/mails/plain/thunderbird.eml")

        Schleuder::Runner.new().run(mail, list.email)
        message = Mail::TestMailer.deliveries.first
        verified = message.verify
        signature_fingerprints = verified.signatures.map(&:fpr)

        expect(Mail::TestMailer.deliveries.size).to eq 1
        expect(message.to).to include('expired@example.org')
        expect(message.to_s).to include("You missed an email from ")
        expect(signature_fingerprints).to eq([list.fingerprint])

        teardown_list_and_mailer(list)
    end

    def teardown_list_and_mailer(list)
      FileUtils.rm_rf(list.listdir)
      Mail::TestMailer.deliveries.clear
    end
  end
end
