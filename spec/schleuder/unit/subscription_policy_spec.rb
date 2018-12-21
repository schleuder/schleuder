require 'spec_helper'

describe AuthorizerPolicies::SubscriptionPolicy do
  context 'read' do
    it 'allows to view the own subscription as subscriber if view-subscriptions is false' do
      list = create(:list, subscriber_permissions: {
          'view-subscriptions' => false,
        })
      subscription1 = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription1.email)
      policy = AuthorizerPolicies::SubscriptionPolicy.new(account, subscription1)
      
      expect(policy.read?).to be true
    end

    it 'allows to view another subscription as subscriber if view-subscriptions is true' do
      list = create(:list, subscriber_permissions: {
          'view-subscriptions' => true,
        })
      subscription1 = create(:subscription, list_id: list.id, admin: false)
      subscription2 = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription1.email)
      policy = AuthorizerPolicies::SubscriptionPolicy.new(account, subscription2)
      
      expect(policy.read?).to be true
    end

    it 'rejects to view another subscription as subscriber if view-subscriptions is false' do
      list = create(:list, subscriber_permissions: {
          'view-subscriptions' => false,
        })
      subscription1 = create(:subscription, list_id: list.id, admin: false)
      subscription2 = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription1.email)
      policy = AuthorizerPolicies::SubscriptionPolicy.new(account, subscription2)
      
      expect(policy.read?).to be false
    end

    it 'allows to view another subscription as admin if view-subscriptions is false' do
      list = create(:list, subscriber_permissions: {
          'view-subscriptions' => false,
        })
      subscription1 = create(:subscription, list_id: list.id, admin: true)
      subscription2 = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription1.email)
      policy = AuthorizerPolicies::SubscriptionPolicy.new(account, subscription2)
      
      expect(policy.read?).to be true
    end
  end

  context 'update' do
    it 'allows to update the own subscription as subscriber if add-subscriptions is false' do
      list = create(:list, subscriber_permissions: {
          'add-subscriptions' => false,
        })
      subscription1 = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription1.email)
      policy = AuthorizerPolicies::SubscriptionPolicy.new(account, subscription1)
      
      expect(policy.update?).to be true
    end

    it 'allows to update another subscription as subscriber if add-subscriptions is true' do
      list = create(:list, subscriber_permissions: {
          'add-subscriptions' => true,
        })
      subscription1 = create(:subscription, list_id: list.id, admin: false)
      subscription2 = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription1.email)
      policy = AuthorizerPolicies::SubscriptionPolicy.new(account, subscription2)
      
      expect(policy.update?).to be true
    end

    it 'rejects to update another subscription as subscriber if add-subscriptions is false' do
      list = create(:list, subscriber_permissions: {
          'add-subscriptions' => false,
        })
      subscription1 = create(:subscription, list_id: list.id, admin: false)
      subscription2 = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription1.email)
      policy = AuthorizerPolicies::SubscriptionPolicy.new(account, subscription2)
      
      expect(policy.update?).to be false
    end

    it 'allows to update another subscription as admin if add-subscriptions is false' do
      list = create(:list, subscriber_permissions: {
          'add-subscriptions' => false,
        })
      subscription1 = create(:subscription, list_id: list.id, admin: true)
      subscription2 = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription1.email)
      policy = AuthorizerPolicies::SubscriptionPolicy.new(account, subscription2)
      
      expect(policy.update?).to be true
    end
  end

  context 'delete' do
    it 'allows to delete the own subscription as subscriber if delete-subscriptions is false' do
      list = create(:list, subscriber_permissions: {
          'delete-subscriptions' => false,
        })
      subscription1 = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription1.email)
      policy = AuthorizerPolicies::SubscriptionPolicy.new(account, subscription1)
      
      expect(policy.delete?).to be true
    end

    it 'allows to delete another subscription as subscriber if delete-subscriptions is true' do
      list = create(:list, subscriber_permissions: {
          'delete-subscriptions' => true,
        })
      subscription1 = create(:subscription, list_id: list.id, admin: false)
      subscription2 = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription1.email)
      policy = AuthorizerPolicies::SubscriptionPolicy.new(account, subscription2)
      
      expect(policy.delete?).to be true
    end

    it 'rejects to delete another subscription as subscriber if delete-subscriptions is false' do
      list = create(:list, subscriber_permissions: {
          'delete-subscriptions' => false,
        })
      subscription1 = create(:subscription, list_id: list.id, admin: false)
      subscription2 = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription1.email)
      policy = AuthorizerPolicies::SubscriptionPolicy.new(account, subscription2)
      
      expect(policy.delete?).to be false
    end

    it 'allows to delete another subscription as admin if delete-subscriptions is false' do
      list = create(:list, subscriber_permissions: {
          'delete-subscriptions' => false,
        })
      subscription1 = create(:subscription, list_id: list.id, admin: true)
      subscription2 = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription1.email)
      policy = AuthorizerPolicies::SubscriptionPolicy.new(account, subscription2)
      
      expect(policy.delete?).to be true
    end
  end
end
