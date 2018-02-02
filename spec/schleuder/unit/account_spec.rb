require "spec_helper"

describe Schleuder::Account do
  it { is_expected.to respond_to :subscriptions }
  it { is_expected.to respond_to :lists }
  it { is_expected.to respond_to :admin_lists }
  it { is_expected.to respond_to :authenticate }
  it { is_expected.to respond_to :password= }

  it "#lists shows all lists of all the account's subscriptions, regardless of admin-flags" do
    list1 = create(:list)
    list2 = create(:list)
    create(:subscription, email: "someone@example.org", list: list1, admin: false)
    create(:subscription, email: "someone@example.org", list: list2, admin: true)
    account = create(:account, email: "someone@example.org")

    expect(account.lists.size).to eql(2)
    expect(account.lists.map(&:id).sort).to eql([list1.id, list2.id])
  end

  it "#admin_lists shows only lists of which the account's subscriptions are admins of" do
    list1 = create(:list)
    list2 = create(:list)
    create(:subscription, email: "someone@example.org", list: list1, admin: false)
    create(:subscription, email: "someone@example.org", list: list2, admin: true)
    account = create(:account, email: "someone@example.org")

    expect(account.admin_lists.size).to eql(1)
    expect(account.admin_lists.map(&:id).sort).to eql([list2.id])
  end

  it "fails to save an account without an email-address" do
    account = Account.new(password: 'bla')

    result = account.save

    expect(result).to be(false)
    expect(account.valid?).to be(false)
  end

  it "fails to save an account without a password" do
    account = Account.new(email: 'bla')

    result = account.save

    expect(result).to be(false)
    expect(account.valid?).to be(false)
  end

  it "#set_new_password! changes and returns the stored password" do
    account = create(:account, password: 'foo')

    expect(account.authenticate('foo')).to be_an(Account)

    new_password = account.set_new_password!

    expect(account.authenticate('foo')).to be(false)
    expect(account.authenticate(new_password)).to be_an(Account)
  end

  it "does not store the password in cleartext" do
    account = create(:account, password: "blabla")

    account = Account.find(account.id)

    expect(account.password).to be(nil)
    expect(account.password_digest).not_to include("blabla")
  end

  it "saves email-addresses always in lower-case" do
    account = create(:account, email: "ME@EXAMPLE.ORG")

    expect(account.email).to eql("me@example.org")
  end

  it "generates random passwords" do
    account = create(:account)
    pw1 = account.send("generate_password")
    pw2 = account.send("generate_password")
    pw3 = account.send("generate_password")

    expect(pw1.size).to be_between(Account::PASSWORD_LENGTH_RANGE.first, Account::PASSWORD_LENGTH_RANGE.last)
    expect(pw2.size).to be_between(Account::PASSWORD_LENGTH_RANGE.first, Account::PASSWORD_LENGTH_RANGE.last)
    expect(pw3.size).to be_between(Account::PASSWORD_LENGTH_RANGE.first, Account::PASSWORD_LENGTH_RANGE.last)
    expect(pw1).not_to eql(pw2)
    expect(pw2).not_to eql(pw3)
    expect(pw3).not_to eql(pw1)
  end
end
