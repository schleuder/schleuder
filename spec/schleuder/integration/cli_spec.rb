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
      expect(list.internal_footer).to be_nil
    end

    it "imports the subscriptions" do
      v2list_path = 'spec/fixtures/v2list'

      output = run_cli("migrate #{v2list_path}")
      list = Schleuder::List.by_recipient('v2list@example.org')
      admins_emails = list.admins.map(&:email)
      subscription_emails = list.subscriptions.map(&:email)

      expect(output).not_to match('Error:')

      expect(admins_emails).to eql(["schleuder2@example.org"])

      expect(subscription_emails).to eql(["anotherone@example.org", "anyone@example.org", "bla@foo", "old@example.org", "schleuder2@example.org", "someone@example.org"])
      expect(list.subscriptions.where(email: "anotherone@example.org").first.fingerprint).to eql('')
      expect(list.subscriptions.where(email: "anyone@example.org").first.fingerprint).to     eql("C4D60F8833789C7CAA44496FD3FFA6613AB10ECE")
      expect(list.subscriptions.where(email: "bla@foo").first.fingerprint).to                eql("87E65ED2081AE3D16BE4F0A5EBDBE899251F2412")
      expect(list.subscriptions.where(email: "old@example.org").first.fingerprint).to        eql("6EE51D78FD0B33DE65CCF69D2104E20E20889F66")
      expect(list.subscriptions.where(email: "schleuder2@example.org").first.fingerprint).to eql("C4D60F8833789C7CAA44496FD3FFA6613AB10ECE")
      expect(list.subscriptions.where(email: "someone@example.org").first.fingerprint).to    eql('')
    end

    it "does not fail on duplicated v2 subscriptions" do
      v2list_path = 'spec/fixtures/v2list_duplicate_members'

      output = run_cli("migrate #{v2list_path}")
      expect(output).not_to match('Error:')
      list = Schleuder::List.by_recipient('v2list@example.org')
      subscription_emails = list.subscriptions.map(&:email)

      expect(subscription_emails).to eq ['schleuder2@example.org']
    end
    it "respects non delivery status of admins" do
      v2list_path = 'spec/fixtures/v2list_admin_non_delivery'

      output = run_cli("migrate #{v2list_path}")
      expect(output).not_to match('Error:')
      list = Schleuder::List.by_recipient('v2list@example.org')
      subscriptions = list.subscriptions
      expect(subscriptions.find{|s| s.email == 'schleuder2@example.org' }.delivery_enabled).to eq false
      subscription_emails = subscriptions.map(&:email)
      expect(subscription_emails.sort).to eq(['schleuder2@example.org',
                                              'schleuder2-member@example.org'].sort)
    end
    it "does not fail on admin without key" do
      v2list_path = 'spec/fixtures/v2list_admin_without_key'

      output = run_cli("migrate #{v2list_path}")
      expect(output).not_to match('Error:')

      list = Schleuder::List.by_recipient('v2list@example.org')
      admin_emails = list.admins.map(&:email)


      expect(admin_emails.sort).to eq( ['schleuder2@example.org',
                                        'schleuder2-nokey@example.org' ].sort)
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
        dirmngr_pid = `pgrep -a dirmngr | grep #{list.listdir}`.split(' ',2).first
        expect(dirmngr_pid).to be_nil
      end
      mail = Mail::TestMailer.deliveries.first

      expect(Mail::TestMailer.deliveries.length).to eq 1
      b = mail.first_plaintext_part.body.to_s
      expect(b).to match(/Refreshing all keys from the keyring of list #{list.email} resulted in this:\n\n/)
      expect(b).to match(/\nThis key was updated \(new signatures\):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo \d{4}-\d{2}-\d{2} \[expired: \d{4}-\d{2}-\d{2}\]\n/)
      expect(b).to match(/\nThis key was updated \(new user-IDs and new signatures\):\n0x6EE51D78FD0B33DE65CCF69D2104E20E20889F66 new@example.org \d{4}-\d{2}-\d{2}\n/)

      teardown_list_and_mailer(list)
    end
    it 'updates keys from the keyserver for only a specific list' do
      list1 = create(:list)
      list2 = create(:list)
      [list1,list2].each do |list|
        list.subscribe("admin@example.org", nil, true)
        list.import_key(File.read("spec/fixtures/expired_key.txt"))
        list.import_key(File.read("spec/fixtures/olduid_key.txt"))
      end

      with_sks_mock do
        Cli.new.refresh_keys list1.email
      end
      mail = Mail::TestMailer.deliveries.first

      expect(Mail::TestMailer.deliveries.length).to eq 1
      b = mail.first_plaintext_part.body.to_s
      expect(b).to match(/Refreshing all keys from the keyring of list #{list1.email} resulted in this:\n\n/)
      expect(b).to match(/\nThis key was updated \(new signatures\):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo \d{4}-\d{2}-\d{2} \[expired: \d{4}-\d{2}-\d{2}\]\n/)
      expect(b).to match(/\nThis key was updated \(new user-IDs and new signatures\):\n0x6EE51D78FD0B33DE65CCF69D2104E20E20889F66 new@example.org \d{4}-\d{2}-\d{2}\n/)

      teardown_list_and_mailer(list1)
      teardown_list_and_mailer(list2)
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
  context '#pin_keys' do
    it 'pins fingerprints on not yet set keys' do
      list = create(:list)
      list.subscribe("admin@example.org", nil, true)
      list.subscribe("schleuder2@example.org", nil, false)
      list.import_key(File.read('spec/fixtures/example_key.txt'))
      expect(list.subscriptions_without_fingerprint.size).to eq 2

      Cli.new.pin_keys

      expect(list.subscriptions_without_fingerprint.size).to eq 1
      expect(list.subscriptions_without_fingerprint.collect(&:email)).to eq ['admin@example.org']

      mail = Mail::TestMailer.deliveries.first

      expect(Mail::TestMailer.deliveries.length).to eq 1
      expect(mail.first_plaintext_part.body.to_s).to eql("While checking all subscriptions of list #{list.email} we were pinning a matching key for the following subscriptions:\n\nschleuder2@example.org: C4D60F8833789C7CAA44496FD3FFA6613AB10ECE")

      teardown_list_and_mailer(list)
    end
    it 'only works on the specific list' do
      list1 = create(:list)
      list2 = create(:list)
      [list1,list2].each do |list|
        list.subscribe("admin@example.org", nil, true)
        list.subscribe("schleuder2@example.org", nil, false)
        list.import_key(File.read('spec/fixtures/example_key.txt'))
        expect(list.subscriptions_without_fingerprint.size).to eq 2
      end

      Cli.new.pin_keys list1.email

      expect(list1.subscriptions_without_fingerprint.size).to eq 1
      expect(list1.subscriptions_without_fingerprint.collect(&:email)).to eq ['admin@example.org']
      expect(list2.subscriptions_without_fingerprint.size).to eq 2

      mail = Mail::TestMailer.deliveries.first

      expect(Mail::TestMailer.deliveries.length).to eq 1
      expect(mail.first_plaintext_part.body.to_s).to eql("While checking all subscriptions of list #{list1.email} we were pinning a matching key for the following subscriptions:\n\nschleuder2@example.org: C4D60F8833789C7CAA44496FD3FFA6613AB10ECE")

      teardown_list_and_mailer(list1)
      teardown_list_and_mailer(list2)
    end

    it 'does not report anything if nothing was done' do
      list = create(:list)
      list.subscribe("admin@example.org", nil, true)
      list.subscribe("schleuder2@example.org", nil, false)
      expect(list.subscriptions_without_fingerprint.size).to eq 2

      Cli.new.pin_keys

      expect(list.subscriptions_without_fingerprint.size).to eq 2
      expect(Mail::TestMailer.deliveries.empty?).to eq true

      teardown_list_and_mailer(list)
    end
  end

  context '#install' do
    it 'exits if a shell-process failed' do
      dbfile = Conf.database["database"]
      tmp_filename = "#{dbfile}.tmp"
      File.rename(dbfile, tmp_filename)
      FileUtils.touch dbfile
      begin
        Cli.new.install
      rescue SystemExit => exc
      end

      expect(exc).to be_present
      expect(exc.status).to eql(1)
      File.rename(tmp_filename, dbfile)
    end
  end

  context '#commands' do
    it 'exits with a status code of 1 in case the command is not implemented' do
      run_cli('not-implemented')

      expect($?.exitstatus).to eq(1)
    end
  end
end
