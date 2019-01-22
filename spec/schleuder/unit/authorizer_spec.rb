require 'spec_helper'

describe Schleuder::Authorizer do
  describe '#authorize!' do
    it 'raises an error if resource is nil' do
      account = create(:account)

      expect do
        Authorizer.new(account).authorize!(nil, :some_action)
      end.to raise_error(Schleuder::Errors::ResourceNotFound)
    end

    it 'does not raise an error if account is authorized' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)

      caught_exception = nil

      begin
        Authorizer.new(account).authorize!(list, :read)
      rescue Schleuder::Errors::Unauthorized => exc
        caught_exception = exc
      end
      expect(caught_exception.class).to eql NilClass
    end

    it 'raises an error if account is NOT authorized' do
      account = create(:account)
      list = create(:list)

      begin
        Authorizer.new(account).authorize!(list, :read)
      rescue Schleuder::Errors::Unauthorized => exc
        caught_exception = exc
      end
      expect(caught_exception.class).to eql Errors::Unauthorized
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
