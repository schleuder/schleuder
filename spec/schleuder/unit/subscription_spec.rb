require "spec_helper"

describe Schleuder::Subscription do
  BOOLEAN_SUBSCRIPTION_ATTRIBUTES =
    [
      :delivery_enabled,
      :admin
  ].freeze

  it "has a valid factory" do
    subscription = create(:subscription)

    expect(subscription).to be_valid
  end

  it { is_expected.to respond_to :list_id }
  it { is_expected.to respond_to :email }
  it { is_expected.to respond_to :fingerprint }
  it { is_expected.to respond_to :admin }
  it { is_expected.to respond_to :delivery_enabled }

  it "is invalid when list_id is blank" do
    subscription = build(:subscription, list_id: "")

    expect(subscription).not_to be_valid
    expect(subscription.errors.messages[:list_id]).to be_present
  end

  it "is invalid when email is nil" do
    subscription = build(:subscription, email: nil)

    expect(subscription).not_to be_valid
    expect(subscription.errors.messages[:email]).to include("can't be blank")
  end

   it "is invalid when email is blank" do
    subscription = build(:subscription, email: "")

    expect(subscription).not_to be_valid
    expect(subscription.errors.messages[:email]).to include("can't be blank")
  end

  it "is invalid when email does not contain an @" do
    subscription = build(:subscription, email: "fooatbar.org")

    expect(subscription).not_to be_valid
    expect(subscription.errors.messages[:email]).to include("is not a valid email address")
  end

  it "normalizes the fingerprint" do
    fingerprint = " 99 991 1000 10"
    subscription = build(:subscription, fingerprint: fingerprint)

    expect(subscription.fingerprint).to eq "99991100010"
  end

  it "is valid when fingerprint is empty" do
    subscription = build(:subscription, fingerprint: "")

    expect(subscription).to be_valid
    expect(subscription.errors.messages[:fingerprint]).to be_blank
  end

  it "is valid when fingerprint is nil" do
    subscription = build(:subscription, fingerprint: nil)

    expect(subscription).to be_valid
    expect(subscription.errors.messages[:fingerprint]).to be_blank
  end

  it "is invalid when fingerprint contains invalid characters" do
    subscription = build(:subscription, fingerprint: "&$$$$123AAA")

    expect(subscription).not_to be_valid
    expect(subscription.errors.messages[:fingerprint]).to include("is not a valid fingerprint")
  end

  BOOLEAN_SUBSCRIPTION_ATTRIBUTES.each do |subscription_attribute|
    it "is invalid if #{subscription_attribute} is nil" do
      subscription = build(:subscription)
      subscription[subscription_attribute] = nil

      expect(subscription).not_to be_valid
      expect(subscription.errors.messages[subscription_attribute]).to include("must be true or false")
    end

    it "is invalid if #{subscription_attribute} is blank" do
      subscription = build(:subscription)
      subscription[subscription_attribute] = ""

      expect(subscription).not_to be_valid
      expect(subscription.errors.messages[subscription_attribute]).to include("must be true or false")
    end
  end
end
