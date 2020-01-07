require 'spec_helper'

describe AuthorizerPolicies::KeyPolicy do
  it 'allows to view a key as subscriber if view-keys is true' do
    list = create(:list, subscriber_permissions: {
        'view-keys' => true,
      })
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    key = list.key('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
    subscription = create(:subscription, list_id: list.id, admin: false, fingerprint: '59C71FB38AEE22E091C78259D06350440F759BD3')
    account = create(:account, email: subscription.email)
    key_policy = AuthorizerPolicies::KeyPolicy.new(account, key)
    
    expect(key_policy.read?).to be true
  end

  it 'rejects to view a key as subscriber if view-keys is false' do
    list = create(:list, subscriber_permissions: {
        'view-keys' => false,
      })
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    key = list.key('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
    subscription = create(:subscription, list_id: list.id, admin: false, fingerprint: '59C71FB38AEE22E091C78259D06350440F759BD3')
    account = create(:account, email: subscription.email)
    key_policy = AuthorizerPolicies::KeyPolicy.new(account, key)
    
    expect(key_policy.read?).to be false
  end

  it 'allows to view a key as admin if view-keys is false' do
    list = create(:list, subscriber_permissions: {
        'view-keys' => false,
      })
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    key = list.key('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
    subscription = create(:subscription, list_id: list.id, admin: true, fingerprint: '59C71FB38AEE22E091C78259D06350440F759BD3')
    account = create(:account, email: subscription.email)
    key_policy = AuthorizerPolicies::KeyPolicy.new(account, key)
    
    expect(key_policy.read?).to be true
  end

  it 'allows to view a key as api_superadmin if view-keys is false' do
    list = create(:list, subscriber_permissions: {
        'view-keys' => false,
      })
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    key = list.key('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
    subscription = create(:subscription, list_id: list.id, admin: false, fingerprint: '59C71FB38AEE22E091C78259D06350440F759BD3')
    account = create(:account, email: subscription.email, api_superadmin: true)
    key_policy = AuthorizerPolicies::KeyPolicy.new(account, key)
    
    expect(key_policy.read?).to be true
  end

  it 'allows to delete a key as subscriber if delete-keys is true' do
    list = create(:list, subscriber_permissions: {
        'delete-keys' => true,
      })
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    key = list.key('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
    subscription = create(:subscription, list_id: list.id, admin: false, fingerprint: '59C71FB38AEE22E091C78259D06350440F759BD3')
    account = create(:account, email: subscription.email)
    key_policy = AuthorizerPolicies::KeyPolicy.new(account, key)
    
    expect(key_policy.delete?).to be true
  end

  it 'rejects to delete a key as subscriber if delete-keys is false' do
    list = create(:list, subscriber_permissions: {
        'delete-keys' => false,
      })
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    key = list.key('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
    subscription = create(:subscription, list_id: list.id, admin: false, fingerprint: '59C71FB38AEE22E091C78259D06350440F759BD3')
    account = create(:account, email: subscription.email)
    key_policy = AuthorizerPolicies::KeyPolicy.new(account, key)
    
    expect(key_policy.delete?).to be false
  end

  it 'allows to delete a key as admin if delete-keys is false' do
    list = create(:list, subscriber_permissions: {
        'delete-keys' => false,
      })
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    key = list.key('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
    subscription = create(:subscription, list_id: list.id, admin: true, fingerprint: '59C71FB38AEE22E091C78259D06350440F759BD3')
    account = create(:account, email: subscription.email)
    key_policy = AuthorizerPolicies::KeyPolicy.new(account, key)
    
    expect(key_policy.delete?).to be true
  end

  it 'allows to delete a key as api_superadmin if delete-keys is false' do
    list = create(:list, subscriber_permissions: {
        'delete-keys' => false,
      })
    list.import_key(File.read('spec/fixtures/example_key.txt'))
    key = list.key('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE')
    subscription = create(:subscription, list_id: list.id, admin: false, fingerprint: '59C71FB38AEE22E091C78259D06350440F759BD3')
    account = create(:account, email: subscription.email, api_superadmin: true)
    key_policy = AuthorizerPolicies::KeyPolicy.new(account, key)
    
    expect(key_policy.delete?).to be true
  end
end
