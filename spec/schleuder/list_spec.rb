require "spec_helper"

describe Schleuder::List do
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
end

