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
    list = Schleuder::List.new(
      email: nil,
      fingerprint: "aaaadddd0000999",
    )

    expect(list).not_to be_valid
    expect(list.errors.messages[:email]).to include("can't be blank")
  end

   it "is invalid when email is blank" do
    list = Schleuder::List.new(
      email: "",
      fingerprint: "aaaadddd0000999",
    )

    expect(list).not_to be_valid
    expect(list.errors.messages[:email]).to include("can't be blank")
  end

  it "is invalid when email does not contain an @" do
    list = Schleuder::List.new(
      email: "fooatbar.org",
      fingerprint: "aaaadddd0000999",
    )

    expect(list).not_to be_valid
    expect(list.errors.messages[:email]).to include("is not a valid email address")
  end

  it "normalizes the fingerprint" do
    fingerprint = " 99 991 1000 10"
    list = Schleuder::List.new(fingerprint: fingerprint)

    expect(list.fingerprint).to eq "99991100010"
  end

  it "is invalid when fingerprint is blank" do
    list = Schleuder::List.new(
      email: "foo@bar.org",
      fingerprint: "",
    )

    expect(list).not_to be_valid
    expect(list.errors.messages[:fingerprint]).to include("can't be blank")
  end

  it "is invalid when fingerprint is nil" do
    list = Schleuder::List.new(
      email: "foo@bar.org",
      fingerprint: nil
    )

    expect(list).not_to be_valid
    expect(list.errors.messages[:fingerprint]).to include("can't be blank")
  end

  it "is invalid when fingerprint contains invalid characters" do
    list = Schleuder::List.new(
      email: "foo@bar.org",
      fingerprint: "&$$$$67923AAA",
    )

    expect(list).not_to be_valid
    expect(list.errors.messages[:fingerprint]).to include("is not a valid fingerprint")
  end

  BOOLEAN_LIST_ATTRIBUTES.each do |list_attribute|
    it "is invalid if #{list_attribute} is nil" do
      list = Schleuder::List.new(
        email: "foo@bar.org",
        fingerprint: "aaaadddd0000999",
        "#{list_attribute}": nil
      )

      expect(list).not_to be_valid
      expect(list.errors.messages[list_attribute]).to include("must be true or false")
    end

    it "is invalid if #{list_attribute} is blank" do
      list = Schleuder::List.new(
        email: "foo@bar.org",
        fingerprint: "aaaadddd0000999",
        "#{list_attribute}": ""
      )

      expect(list).not_to be_valid
      expect(list.errors.messages[list_attribute]).to include("must be true or false")
    end
  end

  [:headers_to_meta, :keywords_admin_only, :keywords_admin_notify].each do |list_attribute|
    it "is invalid if #{list_attribute} contains special characters" do
      list = Schleuder::List.new(
        email: "foo@bar.org",
        fingerprint: "aaaadddd0000999",
        "#{list_attribute}": ["$from", "to", "date", "cc"],
      )

      expect(list).not_to be_valid
      expect(list.errors.messages[list_attribute]).to include("contains invalid characters")
    end

    it "is valid if #{list_attribute} does not contain special characters" do
      list = Schleuder::List.new(
        email: "foo@bar.org",
        fingerprint: "aaaadddd0000999",
        "#{list_attribute}": ["foobar"],
      )

      expect(list).to be_valid
    end
  end

  it "is invalid if bounces_drop_on_headers contains special characters" do
    list = Schleuder::List.new(
      email: "foo@bar.org",
      fingerprint: "aaaadddd0000999",
      bounces_drop_on_headers: {"$": "%"},
    )

    expect(list).not_to be_valid
    expect(list.errors.messages[:bounces_drop_on_headers]).to include("contains invalid characters")
  end

  [:subject_prefix, :subject_prefix_in, :subject_prefix_out].each do |list_attribute|
    it "is invalid if #{list_attribute} contains a linebreak" do
      list = Schleuder::List.new(
        email: "foo@bar.org",
        fingerprint: "aaaadddd0000999",
        "#{list_attribute}": "Foo\nbar",
      )

      expect(list).not_to be_valid
      expect(list.errors.messages[list_attribute]).to include("must not include line-breaks")
    end
  end

  it "is invalid if openpgp_header_preference is foobar" do
    list = Schleuder::List.new(
      email: "foo@bar.org",
      fingerprint: "aaaadddd0000999",
      openpgp_header_preference: "foobar",
    )

    expect(list).not_to be_valid
    expect(list.errors.messages[:openpgp_header_preference]).to include("must be one of: sign, encrypt, signencrypt, unprotected, none")
  end

  [:max_message_size_kb, :logfiles_to_keep].each do |list_attribute|
    it "is invalid if #{list_attribute} is 0" do
      list = Schleuder::List.new(
        email: "foo@bar.org",
        fingerprint: "aaaadddd0000999",
        "#{list_attribute}": 0,
      )

      expect(list).not_to be_valid
      expect(list.errors.messages[list_attribute]).to include("must be a number greater than zero")
    end
  end

  it "is invalid if log_level is foobar" do
    list = Schleuder::List.new(
      email: "foo@bar.org",
      fingerprint: "aaaadddd0000999",
      log_level: "foobar",
    )

    expect(list).not_to be_valid
    expect(list.errors.messages[:log_level]).to include("must be one of: debug, info, warn, error")
  end

  it "is invalid if language is jp" do
    list = Schleuder::List.new(
      email: "foo@bar.org",
      fingerprint: "aaaadddd0000999",
      language: "jp",
    )

    expect(list).not_to be_valid
    expect(list.errors.messages[:language]).to include("must be one of: en, de")
  end

  it "is invalid if public footer include a non-printable characters" do
    list = Schleuder::List.new(
      email: "foo@bar.org",
      fingerprint: "aaaadddd0000999",
      public_footer: "\a",
    )

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
      list = Schleuder::List.new(
        email: "foo@bar.org",
        fingerprint: "aaaadddd0000999",
      )

      expect(list.logfile).to eq "/var/schleuder/lists/bar.org/foo/list.log"
    end
  end

  describe "#logger" do
    it "calls the ListLogger" do
      list = Schleuder::List.new(
        email: "foo@bar.org",
        fingerprint: "aaaadddd0000999",
      )

      expect(Listlogger).to receive(:new).with(list)

      list.logger
    end
  end

  describe "#to_s" do
    it "returns the email" do
      list = Schleuder::List.new(
        email: "foo@bar.org",
        fingerprint: "aaaadddd0000999",
      )

      expect(list.email).to eq "foo@bar.org"
    end
  end
end
