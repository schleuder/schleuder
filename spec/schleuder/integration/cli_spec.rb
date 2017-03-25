require "spec_helper"

describe 'cli' do
  context "migrates a v2-list to v3.0" do
    it 'creates the list' do
      v2list_path = 'spec/fixtures/v2list'

      output = run_cli("migrate #{v2list_path}")
      list = Schleuder::List.by_recipient('v2list@example.org')

      expect(output).to be_present
      expect(list).to be_present
    end

    it "imports the public keys" do
      v2list_path = 'spec/fixtures/v2list'

      output = run_cli("migrate #{v2list_path}")
      list = Schleuder::List.by_recipient('v2list@example.org')

      expect(output).not_to match('Error:')

      keys = list.keys.map(&:fingerprint)
      expect(list.key.fingerprint).to eq '0392CF72B345256BB730049789226FD6A42B2A7A'
      expect(keys).to include 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE'
    end

    it "imports the secret key" do
      v2list_path = 'spec/fixtures/v2list'

      output = run_cli("migrate #{v2list_path}")
      list = Schleuder::List.by_recipient('v2list@example.org')

      expect(output).not_to match('Error:')

      expect(list.secret_key).to be_present
      expect(list.secret_key.fingerprint).to eq '0392CF72B345256BB730049789226FD6A42B2A7A'

      signed = GPGME::Crypto.new(:armor => true).clearsign('lala').read

      expect(signed).to match(/^-----BEGIN PGP SIGNED MESSAGE-----\n.*\n\nlala\n-----BEGIN PGP SIGNATURE-----\n.*\n-----END PGP SIGNATURE-----\n$/m)
    end

    it "imports the config" do
      v2list_path = 'spec/fixtures/v2list'

      output = run_cli("migrate #{v2list_path}")
      list = Schleuder::List.by_recipient('v2list@example.org')

      expect(output).not_to match('Error:')

      expect(list.to_s).to eq 'v2list@example.org'
      expect(list.log_level).to eq 'warn'
      expect(list.fingerprint).to eq '0392CF72B345256BB730049789226FD6A42B2A7A'
      expect(list.keywords_admin_only).to eq %w[subscribe unsubscribe delete-key]
      expect(list.keywords_admin_notify).to eq %w[add-key unsubscribe]
      expect(list.send_encrypted_only).to eq false
      expect(list.receive_encrypted_only).to eq false
      expect(list.receive_signed_only).to eq false
      expect(list.receive_authenticated_only).to eq false
      expect(list.receive_from_subscribed_emailaddresses_only).to eq false
      expect(list.receive_admin_only).to eq false
      expect(list.keep_msgid).to eq true
      expect(list.bounces_drop_all).to eq false
      expect(list.bounces_notify_admins).to eq true
      expect(list.include_list_headers).to eq true
      expect(list.include_openpgp_header).to eq true
      expect(list.openpgp_header_preference).to eq 'signencrypt'
      expect(list.headers_to_meta).to eq %w[from to cc date]
      expect(list.bounces_drop_on_headers).to eq({'x-spam-flag' => "yes"})
      expect(list.subject_prefix).to eq '[v2]'
      expect(list.subject_prefix_in).to eq '[in]'
      expect(list.subject_prefix_out).to eq '[out]'
      expect(list.max_message_size_kb).to eq 10240
      expect(list.public_footer).to eq "-- \nfooter"
    end

    it "imports the subscriptions" do
      v2list_path = 'spec/fixtures/v2list'

      output = run_cli("migrate #{v2list_path}")
      list = Schleuder::List.by_recipient('v2list@example.org')
      subscription_emails = list.subscriptions.map(&:email)

      expect(output).not_to match('Error:')

      expect(subscription_emails).to eq ['schleuder2@example.org']
    end
  end

  context '#refresh_keys' do
    it 'updates keys from the keyserver' do
      list = create(:list)
      list.subscribe("admin@example.org", nil, true)
      list.import_key(File.read("spec/fixtures/expired_key.txt"))
      list.import_key(File.read("spec/fixtures/olduid_key.txt"))

      with_sks_mock do
        Cli.new.refresh_keys
      end
      mail = Mail::TestMailer.deliveries.first

      expect(Mail::TestMailer.deliveries.length).to eq 1
      expect(mail.to_s).to include("Refreshing all keys from the keyring of list #{list.email} resulted in this")
      expect(mail.to_s).to include("Key 98769E8A1091F36BD88403ECF71A3F8412D83889 was updated (new signatures).\r\n")
      expect(mail.to_s).to include("Key 6EE51D78FD0B33DE65CCF69D2104E20E20889F66 was updated (new user-IDs, new signatures).\r\n")

      teardown_list_and_mailer(list)
    end

    it 'reports errors from refreshing keys' do
      list = create(:list)
      list.subscribe("admin@example.org", nil, true)
      list.import_key(File.read("spec/fixtures/expired_key.txt"))

      Cli.new.refresh_keys
      mail = Mail::TestMailer.deliveries.first

      expect(Mail::TestMailer.deliveries.length).to eq 1
      expect(mail.to_s).to include("Refreshing all keys from the keyring of list #{list.email} resulted in this")
      if GPGME::Ctx.sufficient_gpg_version?('2.1')
        expect(mail.to_s).to include("keyserver refresh failed: No keyserver available")
      else
        # The wording differs slightly among versions.
        expect(mail.to_s).to match(/gpgkeys: .* error .* connect/)
      end

      teardown_list_and_mailer(list)
    end
  end
end
