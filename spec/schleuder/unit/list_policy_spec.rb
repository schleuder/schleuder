require 'spec_helper'

describe AuthorizerPolicies::ListPolicy do
  context 'view list-details' do
    it 'allows for subscriber if view-list-config is true' do
      list = create(:list, subscriber_permissions: {
          'view-list-config' => true,
        })
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.read?).to be true
    end

    it 'rejects for subscriber if view-list-config is false' do
      list = create(:list, subscriber_permissions: {
          'view-list-config' => false,
        })
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.read?).to be false
    end

    it 'allows for admin if view-list-config is false' do
      list = create(:list, subscriber_permissions: {
          'view-list-config' => false,
        })
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.read?).to be true
    end
  end

  context 'create new list' do
    it 'allows if api_superadmin' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email, api_superadmin: true)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.create?).to be true
    end

    it 'rejects if not api_superadmin' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email, api_superadmin: false)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.create?).to be false
    end
  end

  context 'delete list' do
    it 'allows if api_superadmin' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email, api_superadmin: true)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.delete?).to be true
    end

    it 'rejects if not api_superadmin' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email, api_superadmin: false)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.delete?).to be false
    end
  end

  context 'update a list' do
    it 'allows if list-admin' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.update?).to be true
    end

    it 'allows if not list-admin but api_superadmin' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email, api_superadmin: true)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.update?).to be true
    end

    it 'rejects if not list-admin' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.update?).to be false
    end
  end

  context 'check_keys' do
    it 'allows if list-admin' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.check_keys?).to be true
    end

    it 'allows if not list-admin but api_superadmin' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email, api_superadmin: true)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.check_keys?).to be true
    end

    it 'rejects if not list-admin' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.check_keys?).to be false
    end
  end

  context 'send_list_key' do
    it 'allows if list-admin' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.send_list_key?).to be true
    end

    it 'allows if not list-admin but api_superadmin' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email, api_superadmin: true)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.send_list_key?).to be true
    end

    it 'rejects if not list-admin' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.send_list_key?).to be false
    end
  end

  context 'view_subscriptions' do
    it 'allows to view subscriptions as subscriber if view-subscriptions is true' do
      list = create(:list, subscriber_permissions: {
          'view-subscriptions' => true
        })
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.read_subscriptions?).to be true
    end

    it 'rejects to view subscriptions as subscriber if view-subscriptions is false' do
      list = create(:list, subscriber_permissions: {
          'view-subscriptions' => false
        })
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.read_subscriptions?).to be false
    end

    it 'allows to view subscriptions as admin if view-subscriptions is false' do
      list = create(:list, subscriber_permissions: {
          'view-subscriptions' => false
        })
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.read_subscriptions?).to be true
    end
  end

  context 'add_subscriptions' do
    it 'allows to add subscriptions as subscriber if add-subscriptions is true' do
      list = create(:list, subscriber_permissions: {
          'add-subscriptions' => true
        })
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.add_subscriptions?).to be true
    end

    it 'rejects to add subscriptions as subscriber if add-subscriptions is false' do
      list = create(:list, subscriber_permissions: {
          'add-subscriptions' => false
        })
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.add_subscriptions?).to be false
    end

    it 'allows to add subscriptions as admin if add-subscriptions is false' do
      list = create(:list, subscriber_permissions: {
          'add-subscriptions' => false
        })
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.add_subscriptions?).to be true
    end
  end

  context 'read_keys' do
    it 'allows to view keys as subscriber if view-keys is true' do
      list = create(:list, subscriber_permissions: {
          'view-keys' => true
        })
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.read_keys?).to be true
    end

    it 'rejects to view keys as subscriber if view-keys is false' do
      list = create(:list, subscriber_permissions: {
          'view-keys' => false
        })
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.read_keys?).to be false
    end

    it 'allows to view keys as admin if view-keys is false' do
      list = create(:list, subscriber_permissions: {
          'view-keys' => false
        })
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.read_keys?).to be true
    end
  end

  context 'add_keys' do
    it 'allows to add keys as subscriber if add-keys is true' do
      list = create(:list, subscriber_permissions: {
          'add-keys' => true
        })
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.add_keys?).to be true
    end

    it 'rejects to add keys as subscriber if add-keys is false' do
      list = create(:list, subscriber_permissions: {
          'add-keys' => false
        })
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.add_keys?).to be false
    end

    it 'allows to add keys as admin if add-keys is false' do
      list = create(:list, subscriber_permissions: {
          'add-keys' => false
        })
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      list_policy = AuthorizerPolicies::ListPolicy.new(account, list)
      
      expect(list_policy.add_keys?).to be true
    end
  end
end
