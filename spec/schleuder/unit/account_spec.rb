require "spec_helper"

describe Schleuder::Account do
  it { is_expected.to respond_to :subscriptions }
  it { is_expected.to respond_to :lists }
  it { is_expected.to respond_to :admin_lists }

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
end
