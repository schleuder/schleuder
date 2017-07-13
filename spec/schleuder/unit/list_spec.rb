require "spec_helper"

describe Schleuder::List do
  BOOLEAN_LIST_ATTRIBUTES =
    [
      :send_encrypted_only, :receive_encrypted_only, :receive_signed_only,
      :receive_authenticated_only, :receive_from_subscribed_emailaddresses_only,
      :receive_admin_only, :keep_msgid, :bounces_drop_all,
      :bounces_notify_admins, :include_list_headers, :include_list_headers,
      :include_openpgp_header, :forward_all_incoming_to_admins
  ].freeze

  it "has a valid factory" do
    list = create(:list_with_one_subscription)

    expect(list).to be_valid
  end

  it { is_expected.to respond_to :subscriptions }
  it { is_expected.to respond_to :email }
  it { is_expected.to respond_to :fingerprint }
  it { is_expected.to respond_to :log_level }
  it { is_expected.to respond_to :subject_prefix }
  it { is_expected.to respond_to :subject_prefix_in }
  it { is_expected.to respond_to :subject_prefix_out }
  it { is_expected.to respond_to :openpgp_header_preference }
  it { is_expected.to respond_to :public_footer }
  it { is_expected.to respond_to :headers_to_meta }
  it { is_expected.to respond_to :bounces_drop_on_headers }
  it { is_expected.to respond_to :keywords_admin_only }
  it { is_expected.to respond_to :keywords_admin_notify }
  it { is_expected.to respond_to :send_encrypted_only }
  it { is_expected.to respond_to :receive_encrypted_only }
  it { is_expected.to respond_to :receive_signed_only }
  it { is_expected.to respond_to :receive_authenticated_only }
  it { is_expected.to respond_to :receive_from_subscribed_emailaddresses_only }
  it { is_expected.to respond_to :receive_admin_only }
  it { is_expected.to respond_to :keep_msgid }
  it { is_expected.to respond_to :bounces_drop_all }
  it { is_expected.to respond_to :bounces_notify_admins }
  it { is_expected.to respond_to :include_list_headers }
  it { is_expected.to respond_to :include_openpgp_header }
  it { is_expected.to respond_to :max_message_size_kb }
  it { is_expected.to respond_to :language }
  it { is_expected.to respond_to :forward_all_incoming_to_admins }
  it { is_expected.to respond_to :logfiles_to_keep }

  it "is invalid when email is nil" do
    # Don't use factory here because we'd run into List.listdir expecting email to not be nil.
    list = Schleuder::List.new(email: nil)

    expect(list).not_to be_valid
    expect(list.errors.messages[:email]).to include("can't be blank")
  end

  it "is invalid when email is blank" do
    list = build(:list, email: "")

    expect(list).not_to be_valid
    expect(list.errors.messages[:email]).to include("can't be blank")
  end

  it "is invalid when email does not contain an @" do
    list = build(:list, email: "fooatbar.org")

    expect(list).not_to be_valid
    expect(list.errors.messages[:email]).to include("is not a valid email address")
  end

  it "normalizes the fingerprint" do
    fingerprint = " 99 991 1000 10"
    list = build(:list, fingerprint: fingerprint)

    expect(list.fingerprint).to eq "99991100010"
  end

  it "is invalid when fingerprint is blank" do
    list = build(:list, fingerprint: "")

    expect(list).not_to be_valid
    expect(list.errors.messages[:fingerprint]).to include("can't be blank")
  end

  it "is invalid when fingerprint is nil" do
    list = build(:list, fingerprint: nil)

    expect(list).not_to be_valid
    expect(list.errors.messages[:fingerprint]).to include("can't be blank")
  end

  it "is invalid when fingerprint contains invalid characters" do
    list = build(:list, fingerprint: "&$$$$67923AAA")

    expect(list).not_to be_valid
    expect(list.errors.messages[:fingerprint]).to include("is not a valid OpenPGP-fingerprint")
  end

  BOOLEAN_LIST_ATTRIBUTES.each do |list_attribute|
    it "is invalid if #{list_attribute} is nil" do
      list = build(:list)
      list[list_attribute] = nil

      expect(list).not_to be_valid
      expect(list.errors.messages[list_attribute]).to include("must be true or false")
    end

    it "is invalid if #{list_attribute} is blank" do
      list = build(:list)
      list[list_attribute] = ""

      expect(list).not_to be_valid
      expect(list.errors.messages[list_attribute]).to include("must be true or false")
    end
  end

  [:headers_to_meta, :keywords_admin_only, :keywords_admin_notify].each do |list_attribute|
    it "is invalid if #{list_attribute} contains special characters" do
      list = build(:list)
      list[list_attribute] =["$from", "to", "date", "cc"]

      expect(list).not_to be_valid
      expect(list.errors.messages[list_attribute]).to include("contains invalid characters")
    end

    it "is valid if #{list_attribute} does not contain special characters" do
      list = build(:list)
      list[list_attribute] = ["foobar"]

      expect(list).to be_valid
    end
  end

  it "is invalid if bounces_drop_on_headers contains special characters" do
    list = build(:list, bounces_drop_on_headers: {"$" => "%"})

    expect(list).not_to be_valid
    expect(list.errors.messages[:bounces_drop_on_headers]).to include("contains invalid characters")
  end

  [:subject_prefix, :subject_prefix_in, :subject_prefix_out].each do |list_attribute|
    it "is invalid if #{list_attribute} contains a linebreak" do
      list = build(:list)
      list[list_attribute] = "Foo\nbar"

      expect(list).not_to be_valid
      expect(list.errors.messages[list_attribute]).to include("must not include line-breaks")
    end

    it "is valid if #{list_attribute} is nil" do
      list = build(:list)
      list[list_attribute] = nil

      expect(list).to be_valid
    end
  end

  it "is invalid if openpgp_header_preference is foobar" do
    list = build(:list, openpgp_header_preference: "foobar")

    expect(list).not_to be_valid
    expect(list.errors.messages[:openpgp_header_preference]).to include("must be one of: sign, encrypt, signencrypt, unprotected, none")
  end

  [:max_message_size_kb, :logfiles_to_keep].each do |list_attribute|
    it "is invalid if #{list_attribute} is 0" do
      list = build(:list)
      list[list_attribute] = 0

      expect(list).not_to be_valid
      expect(list.errors.messages[list_attribute]).to include("must be a number greater than zero")
    end
  end

  it "is invalid if log_level is foobar" do
    list = build(:list, log_level: "foobar")

    expect(list).not_to be_valid
    expect(list.errors.messages[:log_level]).to include("must be one of: debug, info, warn, error")
  end

  it "is invalid if language is jp" do
    list = build(:list, language: "jp")

    expect(list).not_to be_valid
    expect(list.errors.messages[:language]).to include("must be one of: en, de")
  end

  it "is invalid if public_footer includes a non-printable character" do
    list = build(:list, public_footer: "\a")

    expect(list).not_to be_valid
    expect(list.errors.messages[:public_footer]).to include("includes non-printable characters")
  end

  describe ".configurable_attributes" do
    it "returns an array that contains the configurable attributes" do
      expect(Schleuder::List.configurable_attributes).to eq [
       :bounces_drop_all, :bounces_drop_on_headers, :bounces_notify_admins,
       :forward_all_incoming_to_admins, :headers_to_meta, :include_list_headers,
       :include_openpgp_header, :keep_msgid, :keywords_admin_notify, :keywords_admin_only,
       :language, :log_level, :logfiles_to_keep, :max_message_size_kb, :openpgp_header_preference,
       :public_footer, :receive_admin_only, :receive_authenticated_only, :receive_encrypted_only,
       :receive_from_subscribed_emailaddresses_only, :receive_signed_only, :send_encrypted_only,
       :subject_prefix, :subject_prefix_in, :subject_prefix_out,
      ]
    end

    it "does not contain the attributes email and fingerprint" do
      expect(Schleuder::List.configurable_attributes).to_not include(:email)
      expect(Schleuder::List.configurable_attributes).to_not include(:fingerprint)
    end
  end

  describe "#logfile" do
    it "returns the logfile path" do
      list = create(:list, email: "foo@bar.org")

      expect(list.logfile).to eq File.join(Schleuder::Conf.listlogs_dir, "bar.org/foo/list.log")
    end
  end

  describe "#logger" do
    it "calls the ListLogger" do
      list = create(:list)

      expect(Listlogger).to receive(:new).with(list)

      list.logger
    end
  end

  describe "#to_s" do
    it "returns the email" do
      list = create(:list, email: "foo@bar.org")

      expect(list.email).to eq "foo@bar.org"
    end
  end

  describe "#admins" do
    it "returns subscriptions of admin users" do
      list = create(:list)
      admin_subscription = create(
        :subscription,
        email: "admin@foo.org",
        admin: true,
        list_id: list.id,
      )
      _user_subscription = create(
        :subscription,
        email: "user@foo.org",
        admin: false,
        list_id: list.id,
      )

      expect(list.admins).to eq [admin_subscription]
    end
  end

  describe "#key" do
    it "returns the key with the fingerprint of the list" do
      list = create(
        :list,
        fingerprint: "59C7 1FB3 8AEE 22E0 91C7  8259 D063 5044 0F75 9BD3"
      )

      expect(list.key.fingerprint()).to eq "59C71FB38AEE22E091C78259D06350440F759BD3"
    end
  end

  describe "#secret_key" do
    it "returns the secret key with the fingerprint of the list" do
      list = create(
        :list,
        fingerprint: "59C71FB38AEE22E091C78259D06350440F759BD3"
      )

      expect(list.secret_key.secret?).to eq true
      expect(list.secret_key.fingerprint).to eq "59C71FB38AEE22E091C78259D06350440F759BD3"
    end
  end

  describe "#keys" do
    it "it returns an array with the keys of the list" do
      list = create(:list)

      expect(list.keys).to be_kind_of Array
      expect(list.keys.length).to eq 1
    end

    it "returns an array of keys matching the given fingerprint" do
      list = create(
        :list,
        fingerprint: "59C71FB38AEE22E091C78259D06350440F759BD3"
      )

      expect(list.keys).to be_kind_of Array
      expect(list.keys.first.fingerprint).to eq "59C71FB38AEE22E091C78259D06350440F759BD3"
    end

    it "returns an array with the keys matching the given email address" do
      list = create(:list, email: "schleuder@example.org")

      expect(list.keys("schleuder@example.org").length).to eq 1
      expect(
        list.keys("schleuder@example.org").first.fingerprint
      ).to eq "59C71FB38AEE22E091C78259D06350440F759BD3"
    end

    it "returns an array with the keys matching the given bracketed email address" do
      list = create(:list, email: "schleuder@example.org")

      expect(
        list.keys("bla <schleuder@example.org>").first.fingerprint
      ).to eq "59C71FB38AEE22E091C78259D06350440F759BD3"
    end
  end

  describe "#import_key" do
    it "imports a given key" do
      list = create(:list)
      key = File.read("spec/fixtures/example_key.txt")

      expect { list.import_key(key) }.to change { list.keys.count }.by(1)

      list.delete_key("C4D60F8833789C7CAA44496FD3FFA6613AB10ECE")
    end
  end

  describe "#delete_key" do
    it "deletes the key with the given fingerprint" do
      list = create(:list)
      key = File.read("spec/fixtures/example_key.txt")
      list.import_key(key)

      expect do
        list.delete_key("C4D60F8833789C7CAA44496FD3FFA6613AB10ECE")
      end.to change { list.keys.count }.by(-1)
    end

    it "returns false if no key with the fingerprint was found" do
      list = create(:list)

      expect(list.delete_key("A4C60C8833789C7CAA44496FD3FFA6611AB10CEC")).to eq false
    end
  end

  describe "#export_key" do
    it "exports the key with the fingerprint of the list if no argument is given" do
      list = create(:list, email: "schleuder@example.org")
      expected_public_key = File.read("spec/fixtures/schleuder_at_example_public_key.txt")
      # Get rid of the first, opening line, so we don't compare against optional comments in the output, etc.
      expected_public_key = expected_public_key.split("\n").slice(1..-1).join("\n")

      expect(list.export_key()).to include expected_public_key
    end
  end

  it "exports the key with the given fingerprint" do
    list = create(:list, email: "schleuder@example.org")
    expected_public_key = File.read("spec/fixtures/schleuder_at_example_public_key.txt")
    # Get rid of the first, opening line, so we don't compare against optional comments in the output, etc.
    expected_public_key = expected_public_key.split("\n").slice(1..-1).join("\n")

    expect(
      list.export_key("59C71FB38AEE22E091C78259D06350440F759BD3")
    ).to include expected_public_key
  end

  describe "#check_keys" do
    it "adds a mesage if a key expires in two weeks or less" do
      list = create(:list)
      key = double("key")
      generation_time = Time.now - 1.year
      expiry_time = Time.now + 7.days
      allow_any_instance_of(GPGME::Key).to receive(:subkeys).and_return(key)
      allow(key).to receive(:first).and_return(key)
      allow(key).to receive(:timestamp).and_return(generation_time)
      allow(key).to receive(:expires?).and_return(true)
      allow(key).to receive(:expired?).and_return(false)
      allow(key).to receive(:expired).and_return(false)
      allow(key).to receive(:any?).and_return(false)
      allow(key).to receive(:expires).and_return(expiry_time)
      allow(key).to receive(:fingerprint).and_return("59C71FB38AEE22E091C78259D06350440F759BD3")

      datefmt = "%Y-%m-%d"
      generation_date = generation_time.strftime(datefmt)
      expiry_date = expiry_time.strftime(datefmt)
      expect(list.check_keys).to eq "This key expires in 6 days:\n0x59C71FB38AEE22E091C78259D06350440F759BD3 schleuder@example.org #{generation_date} [expires: #{expiry_date}]\n\n"
    end

    it "adds a message if a key is revoked" do
      list = create(:list)
      allow_any_instance_of(GPGME::Key).to receive(:trust).and_return(:revoked)

      expect(list.check_keys).to eq "This key is revoked:\n0x59C71FB38AEE22E091C78259D06350440F759BD3 schleuder@example.org 2016-12-06 [revoked]\n\n"
    end

    it "adds a message if a key is disabled" do
      list = create(:list)
      allow_any_instance_of(GPGME::Key).to receive(:trust).and_return(:disabled)

      expect(list.check_keys).to eq "This key is disabled:\n0x59C71FB38AEE22E091C78259D06350440F759BD3 schleuder@example.org 2016-12-06 [disabled]\n\n"
    end

    it "adds a message if a key is invalid" do
      list = create(:list)
      allow_any_instance_of(GPGME::Key).to receive(:trust).and_return(:invalid)

      expect(list.check_keys).to eq "This key is invalid:\n0x59C71FB38AEE22E091C78259D06350440F759BD3 schleuder@example.org 2016-12-06 [invalid]\n\n"
    end
  end

  describe ".by_recipient" do
    it "returns the list for a given address" do
      list = create(:list, email: "list@example.org")

      expect(Schleuder::List.by_recipient("list-owner@example.org")).to eq list
    end
  end

  describe "#sendkey_address" do
    it "adds the sendkey keyword to the email address" do
      list = create(:list, email: "list@example.org")

      expect(list.sendkey_address).to eq "list-sendkey@example.org"
    end
  end

  describe "#request_address" do
    it "adds the request keyword to the email address" do
      list = create(:list, email: "list@example.org")

      expect(list.request_address).to eq "list-request@example.org"
    end
  end

  describe "#owner_address" do
    it "adds the owner keyword to the email address" do
      list = create(:list, email: "list@example.org")

      expect(list.owner_address).to eq "list-owner@example.org"
    end
  end

  describe "#bounce_address" do
    it "adds the bounce keyword to the email address" do
      list = create(:list, email: "list@example.org")

      expect(list.bounce_address).to eq "list-bounce@example.org"
    end
  end

  describe "#gpg" do
    it "returns an instance of GPGME::Ctx" do
      list = create(:list)

      expect(list.gpg).to be_an_instance_of GPGME::Ctx
    end

    it "sets the GNUPGHOME environment variable to the listdir" do
      list = create(:list)

      list.gpg

      expect(ENV["GNUPGHOME"]).to eq list.listdir
    end
  end

  context '#fetch_keys' do
    it 'fetches one key by fingerprint' do
      list = create(:list)
      list.subscribe("admin@example.org", nil, true)
      output = ''

      with_sks_mock do
        output = list.fetch_keys('98769E8A1091F36BD88403ECF71A3F8412D83889')
      end

      expect(output).to include("This key was fetched (new key):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo 2010-08-13 [expired: 2017-01-20]")

      teardown_list_and_mailer(list)
    end

    it 'fetches one key by URL' do
      list = create(:list)
      list.subscribe("admin@example.org", nil, true)
      output = ''

      with_sks_mock do
        output = list.fetch_keys('http://127.0.0.1:9999/keys/example.asc')
      end

      expect(output).to include("This key was fetched (new key):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo 2010-08-13 [expired: 2017-01-20]")

      teardown_list_and_mailer(list)
    end

    it 'fetches one key by email address' do
      list = create(:list)
      list.subscribe("admin@example.org", nil, true)
      output = ''

      with_sks_mock do
        output = list.fetch_keys('admin@example.org')
      end

      expect(output).to include("This key was fetched (new key):\n0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo 2010-08-13 [expired: 2017-01-20]")

      teardown_list_and_mailer(list)
    end
  end

  describe "send_list_key_to_subscriptions" do
    it "sends its key to all subscriptions" do
      list = create(:list, send_encrypted_only: false)
      list.subscribe("admin@example.org", nil, true)
      list.send_list_key_to_subscriptions

      raw = Mail::TestMailer.deliveries.first

      expect(raw.parts.first.parts.first.body.to_s).to eql("Find the key for this address attached.")
      expect(raw.parts.first.parts.last.body.to_s).to include("4096R/59C71FB38AEE22E091C78259D06350440F759BD3")
      expect(raw.parts.first.parts.last.body.to_s).to include("-----BEGIN PGP PUBLIC KEY BLOCK-----")
    end
  end

  describe "#subscribe" do
    it "subscribes and ignores nil-values for admin and delivery_enabled" do
      list = create(:list)
      sub, _ = list.subscribe("admin@example.org", nil, nil, nil)

      expect(sub.admin?).to be(false)
      expect(sub.delivery_enabled?).to be(true)
    end

    it "subscribes and sets the fingerprint from key material that contains exactly one key" do
      list = create(:list)
      key_material = File.read("spec/fixtures/example_key.txt")
      sub, msgs = list.subscribe("admin@example.org", "", true, true, key_material)

      expect(msgs).to be(nil)
      expect(sub.fingerprint).to eql("C4D60F8833789C7CAA44496FD3FFA6613AB10ECE")
      expect(list.subscriptions.size).to be(1)
      expect(list.subscriptions.first.fingerprint).to eql("C4D60F8833789C7CAA44496FD3FFA6613AB10ECE")
      expect(list.keys.size).to be(2)
      expect(list.keys.map(&:fingerprint)).to eql(["59C71FB38AEE22E091C78259D06350440F759BD3", "C4D60F8833789C7CAA44496FD3FFA6613AB10ECE"])
    end

    it "subscribes and does not set the fingerprint from key material containing multiple keys" do
      list = create(:list)
      key_material = File.read("spec/fixtures/example_key.txt")
      key_material << File.read("spec/fixtures/olduid_key.txt")
      sub, msgs = list.subscribe("admin@example.org", "", true, true, key_material)

      expect(msgs).to eql("The given key material contained more than one key, could not determine which fingerprint to use. Please set it manually!")
      expect(sub.fingerprint).to be_blank
      expect(list.subscriptions.size).to be(1)
      expect(list.subscriptions.first.fingerprint).to be_blank
      expect(list.keys.size).to be(3)
      expect(list.keys.map(&:fingerprint)).to eql(["59C71FB38AEE22E091C78259D06350440F759BD3", "C4D60F8833789C7CAA44496FD3FFA6613AB10ECE", "6EE51D78FD0B33DE65CCF69D2104E20E20889F66"])
    end

    it "subscribes and does not set the fingerprint from key material containing no keys" do
      list = create(:list)
      key_material = "blabla"
      sub, msgs = list.subscribe("admin@example.org", "", true, true, key_material)

      expect(msgs).to eql("The given key material did not contain any keys!")
      expect(sub.fingerprint).to be_blank
      expect(list.subscriptions.size).to be(1)
      expect(list.subscriptions.first.fingerprint).to be_blank
      expect(list.keys.size).to be(1)
      expect(list.keys.map(&:fingerprint)).to eql(["59C71FB38AEE22E091C78259D06350440F759BD3"])
    end

    it "subscribes and ignores a given fingerprint if key material is given, too" do
      list = create(:list)
      key_material = "blabla"
      sub, msgs = list.subscribe("admin@example.org", "C4D60F8833789C7CAA44496FD3FFA6613AB10ECE", true, true, key_material)

      expect(msgs).to eql("The given key material did not contain any keys!")
      expect(sub.fingerprint).to be_blank
      expect(list.subscriptions.size).to be(1)
      expect(list.subscriptions.first.fingerprint).to be_blank
      expect(list.keys.size).to be(1)
      expect(list.keys.map(&:fingerprint)).to eql(["59C71FB38AEE22E091C78259D06350440F759BD3"])
    end
  end
end
