require 'spec_helper'

describe Schleuder::ListsController do
  describe '#find_all' do
    it 'returns the lists that belong to the account' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      account = create(:account, email: subscription.email)

      lists = ListsController.new(account).find_all

      expect(lists.length).to eq 1
      expect(lists).to eq [list]
    end

    it 'returns an empty array if the account does not belong to any lists' do
      account = create(:account)

      lists = ListsController.new(account).find_all

      expect(lists).to eq []
    end
  end

  describe '#create' do
    it 'creates a list' do
      account = create(:account, email: 'api-superadmin@localhost', api_superadmin: true)
      listname = 'test_list@example.org'
      adminaddress = 'admin@example.org'
      adminkey = File.read('spec/fixtures/example_key.txt')

      list, _messages = ListsController.new(account).create(listname, nil, adminaddress, nil, adminkey)

      expect(list).to be_an_instance_of Schleuder::List
      expect(list).to be_valid
    end

    it 'raises an unauthorized error when the user is not authorized' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      unauthorized_account = create(:account, email: subscription.email)
      listname = 'test_list@example.org'
      adminaddress = 'admin@example.org'
      adminkey = File.read('spec/fixtures/example_key.txt')

      expect do
        ListsController.new(unauthorized_account).create(listname, nil, adminaddress, nil, adminkey)
      end.to raise_error(Schleuder::Errors::Unauthorized)
    end
  end

  describe '#get_configurable_attributes' do
    it 'returns the configurable attributes of the list' do
      account = create(:account)

      configurable_attributes = ListsController.new(account).get_configurable_attributes

      expect(configurable_attributes).to eq [
       :bounces_drop_all, :bounces_drop_on_headers, :bounces_notify_admins, :deliver_selfsent,
       :forward_all_incoming_to_admins, :headers_to_meta, :include_autocrypt_header,
       :include_list_headers, :include_openpgp_header, :internal_footer, :keep_msgid,
       :keywords_admin_notify, :language, :log_level, :logfiles_to_keep, :max_message_size_kb,
       :munge_from, :openpgp_header_preference, :public_footer, :receive_admin_only,
       :receive_authenticated_only, :receive_encrypted_only,
       :receive_from_subscribed_emailaddresses_only, :receive_signed_only,
       :send_encrypted_only, :set_reply_to_to_sender, :subject_prefix,
       :subject_prefix_in, :subject_prefix_out, :subscriber_permissions
      ]
    end
  end

  describe '#send_list_key_to_subscriptions' do
    it 'calls send_list_key_to_subscriptions' do
      account = create(:account, email: 'api-superadmin@localhost', api_superadmin: true)
      list = create(:list)

      allow_any_instance_of(List).to receive(:send_list_key_to_subscriptions).and_return(true)

      expect(ListsController.new(account).send_list_key_to_subscriptions(list.email)).to eq true
    end

    it 'raises an unauthorized error when the user is not authorized' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: false)
      unauthorized_account = create(:account, email: subscription.email)

      expect do
        ListsController.new(unauthorized_account).send_list_key_to_subscriptions(list.email)
      end.to raise_error(Schleuder::Errors::Unauthorized)
    end
  end

  describe '#new_list' do
    it 'returns a new list' do
      account = create(:account)

      expect(ListsController.new(account).new_list).to be_an_instance_of List
    end
  end

  describe '#find' do
    it 'returns a list for a given list email address' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)

      expect(ListsController.new(account).find(list.email)).to eq list
    end

    it 'raises an unauthorized error when the user is not authorized' do
      list = create(:list)
      unauthorized_account = create(:account)

      expect do
        ListsController.new(unauthorized_account).find(list.email)
      end.to raise_error(Schleuder::Errors::Unauthorized)
    end
  end

  describe '#update' do
    it 'updates a list' do
      list = create(:list)
      subscription = create(:subscription, list_id: list.id, admin: true)
      account = create(:account, email: subscription.email)
      attributes = { 'email' => 'new_address@example.org' }

      ListsController.new(account).update(list.email, attributes)
      list.reload

      expect(list.email).to eq 'new_address@example.org'
    end

    it 'raises an unauthorized error when the user is not authorized' do
      list = create(:list)
      unauthorized_account = create(:account)
      attributes = { 'email' => 'new_address@example.org' }

      expect do
        ListsController.new(unauthorized_account).update(list.email, attributes)
      end.to raise_error(Schleuder::Errors::Unauthorized)
    end
  end

  describe '#delete' do
    it 'deletes a list' do
      list = create(:list)
      account = create(:account, email: 'api-superadmin@localhost', api_superadmin: true)

      expect do
        ListsController.new(account).delete(list.email)
      end.to change { List.count }.by -1
    end
  end

  it 'raises an unauthorized error when the user is not authorized' do
    list = create(:list)
    unauthorized_account = create(:account)

    expect do
      ListsController.new(unauthorized_account).delete(list.email)
    end.to raise_error(Schleuder::Errors::Unauthorized)
  end
end
