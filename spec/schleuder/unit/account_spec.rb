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
    
    res = account.save

    expect(res).to be(false)
    expect(account.valid?).to be(false)
  end

  it "fails to save an account without a password" do
    account = Account.new(email: 'bla')
    
    res = account.save

    expect(res).to be(false)
    expect(account.valid?).to be(false)
  end

  it "#set_new_password! changes and returns the stored password" do
    account = create(:account, password: 'foo')

    expect(account.authenticate('foo')).to be_an(Account)

    new_password = account.set_new_password!

    expect(account.authenticate('foo')).to be(false)
    expect(account.authenticate(new_password)).to be_an(Account)
  end
end
