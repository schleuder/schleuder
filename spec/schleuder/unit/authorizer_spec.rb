require 'spec_helper'

describe Schleuder::Authorizer do
  describe '#authorized?' do
    it 'returns nil when resource is nil' do
      account = create(:account)

      expect(Authorizer.new(account).authorized?(nil, :some_action)).to eq nil
    end

    it 'returns true if account is authorized' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)

      expect(Authorizer.new(account).authorized?(list, :read)).to eq true
    end

    it 'returns false if account is NOT authorized' do
      account = create(:account)
      list = create(:list)

      expect(Authorizer.new(account).authorized?(list, :read)).to eq false
    end
  end

  describe '#scoped' do
    it 'returns the scope for a scubscriber as defined in the policy (e.g. list)' do
      list1 = create(:list)
      subscription = create(:subscription, list_id: list1.id, admin: false)
      account = create(:account, email: subscription.email)
      _list2 = create(:list)

      expect(Authorizer.new(account).scoped(List)).to eq [list1]
    end

    it 'returns the scope for a api_superadmin as defined in the policy (e.g. list)' do
      account = create(:superadmin_account)
      list1 = create(:list)
      create(:subscription, list_id: list1.id)
      list2 = create(:list)

      expect(Authorizer.new(account).scoped(List)).to eq [list1, list2]
    end
  end
end
