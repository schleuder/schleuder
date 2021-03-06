require 'spec_helper'

describe Schleuder::SubscriptionsController do
  describe '#find_all' do
    it 'returns the subscriptions of the current account and the given list email' do
      list = create(:list, email: 'somelist@example.org')
      subscription = create(:subscription, list_id: list.id, admin: true)
      _other_subscription = create(:subscription)
      account = create(:account, email: subscription.email)

      subscriptions = SubscriptionsController.new(account).find_all(list.email)

      expect(subscriptions.length).to eq 1
      expect(subscriptions).to eq [subscription]
    end

    it 'returns the subscriptions of the current account filtered by list email' do
      list = create(:list, email: 'somelist@example.org')
      subscription = create(:subscription, list_id: list.id, admin: true, email: 'admin@example.org')
      _other_subscription = create(:subscription, list_id: list.id, admin: true, email: 'other_admin@example.org')
      account = create(:account, email: 'admin@example.org')
      filter = { email: 'admin@example.org' }

      subscriptions = SubscriptionsController.new(account).find_all(list.email, filter)

      expect(subscriptions.length).to eq 1
      expect(subscriptions).to eq [subscription]
    end

    it 'raises an unauthorized error when the user is not authorized' do
      list = create(:list)
      unauthorized_account = create(:account, email: 'unauthorized@example.org')

      expect do
        SubscriptionsController.new(unauthorized_account).find_all(list.email)
      end.to raise_error(Schleuder::Errors::Unauthorized)
    end
  end

  describe 'find subscription by email' do
    it 'returns the subscription with the given email' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)

      expected_subscription = SubscriptionsController.new(account).find(list.email, subscription.email)

      expect(expected_subscription).to eq subscription
    end

    it 'raises an unauthorized error when the user is not authorized' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id)
      unauthorized_account = create(:account, email: 'unauthorized@example.org')

      expect do
        SubscriptionsController.new(unauthorized_account).find(list.email, subscription.email)
      end.to raise_error(Schleuder::Errors::Unauthorized)
    end
  end

  describe '#subscribe' do
    it 'returns a subscription and potential error messages' do
      list = create(:list, email: 'somelist@example.org')
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      attributes = {
        'email' => 'foo@example.org',
        'fingerprint' => '59C71FB38AEE22E091C78259D06350440F759BD3',
        'admin' => false,
        'delivery_enabled' => true
      }
      key_material = File.read('spec/fixtures/partially_expired_key.txt')

      result = SubscriptionsController.new(account).subscribe(list.email, attributes, key_material)

      expect(result[0].email).to eq 'foo@example.org'
      expect(result[0]).to be_an_instance_of Schleuder::Subscription
    end

    it 'raises an unauthorized error when the user is not authorized' do
      list = create(:list)
      unauthorized_account = create(:account, email: 'unauthorized@example.org')
      attributes = {
        'email' => 'foo@example.org',
        'fingerprint' => '59C71FB38AEE22E091C78259D06350440F759BD3',
        'admin' => false,
        'delivery_enabled' => true
      }

      expect do
        SubscriptionsController.new(unauthorized_account).subscribe(list.email, attributes, nil)
      end.to raise_error(Schleuder::Errors::Unauthorized)
    end
  end

  describe '#get_configurable_attributes' do
    it 'returns the configurable_attributes of the Subscription' do
      account = create(:account)

      configurable_attributes = SubscriptionsController.new(account).get_configurable_attributes

      expect(configurable_attributes).to eq ['fingerprint', 'admin', 'delivery_enabled']
    end
  end

  describe 'new' do
    it 'returns a new subscription' do
      account = create(:account)

      expect(SubscriptionsController.new(account).new_subscription).to be_an_instance_of Subscription
    end
  end

  describe 'update' do
    it 'updates the subscription with the given email address' do
      list = create(:list, email: 'somelist@example.org')
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      attributes = {
        'email' => 'new@example.org',
        'fingerprint' => '88C71FB38AEE22E091C78259D06350440F759BD3',
        'admin' => true,
        'delivery_enabled' => false
      }

      SubscriptionsController.new(account).update(list.email, subscription.email, attributes)

      subscription.reload
      expect(subscription.id).to eq subscription.id
      expect(subscription.email).to eq 'new@example.org'
      expect(subscription.fingerprint).to eq '88C71FB38AEE22E091C78259D06350440F759BD3'
      expect(subscription.admin).to eq true
    end

    it 'returns the updated subscription' do
      list = create(:list, email: 'somelist@example.org')
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)
      attributes = {
        'email' => 'new@example.org',
        'fingerprint' => '88C71FB38AEE22E091C78259D06350440F759BD3',
        'admin' => true,
        'delivery_enabled' => false
      }

      subscription = SubscriptionsController.new(account).update(list.email, subscription.email, attributes)

      expect(subscription).to be_valid
      expect(subscription.id).to eq subscription.id
      expect(subscription.email).to eq 'new@example.org'
      expect(subscription.fingerprint).to eq '88C71FB38AEE22E091C78259D06350440F759BD3'
      expect(subscription.admin).to eq true
    end

    it 'raises an unauthorized error when the user is not authorized' do
      list = create(:list)
      subscription = create(:subscription)
      unauthorized_account = create(:account, email: 'unauthorized@example.org')
      attributes = {
        'email' => 'new@example.org',
      }

      expect do
        SubscriptionsController.new(unauthorized_account).update(list.email, subscription.email, attributes)
      end.to raise_error(Schleuder::Errors::Unauthorized)
    end
  end

  describe 'delete' do
    it 'deletes the subscription with the given id' do
      list = create(:list, email: 'somelist@example.org')
      admin = create(:subscription, list_id: list.id, admin: true)
      subscription = create(:subscription, list_id: list.id)
      admin_account = create(:account, email: admin.email)

      SubscriptionsController.new(admin_account).delete(list.email, subscription.email)

      expect{ subscription.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'does not delete the only admin of a list' do
      list = create(:list, email: 'somelist@example.org')
      admin = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: admin.email)

      expect do
        SubscriptionsController.new(account).delete(list.email, admin.email)
      end.to raise_error(Errors::LastAdminNotDeletable)

      expect(admin.reload.id).to eql(admin.id)
    end

    it 'raises an unauthorized error when the user is not authorized' do
      list = create(:list)
      subscription = create(:subscription)
      unauthorized_account = create(:account, email: 'unauthorized@example.org')

      expect do
        SubscriptionsController.new(unauthorized_account).delete(list.email, subscription.email)
      end.to raise_error(Schleuder::Errors::Unauthorized)
    end
  end
end
