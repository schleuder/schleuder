require "spec_helper"

describe Schleuder::ListBuilder do

  it "creates a new, valid list" do
    listname = "list-#{rand}@example.org"
    adminaddress = 'schleuder2@example.org'
    adminkey = File.read('spec/fixtures/example_key.txt')
    list, messages = ListBuilder.new({email: listname, fingerprint: nil}, adminaddress, adminkey).run
    expect(list).to be_an_instance_of Schleuder::List
    expect(list).to be_valid
    expect(messages).to be_blank
  end

  it "returns an error-message if given an invalid email-address" do
    listname = "list-#{rand}"
    adminaddress = 'schleuder2@example.org'
    adminkey = File.read('spec/fixtures/example_key.txt')
    list, messages = ListBuilder.new({email: listname, fingerprint: nil}, adminaddress, adminkey).run
    expect(list).to be_nil
    expect(messages).to be_an_instance_of Hash
    expect(messages.keys).to eq ['email']
    expect(messages.values).to be_present
  end

  it "creates a listdir for the list" do
    listname = "list-#{rand}@example.org"
    adminaddress = 'schleuder2@example.org'
    adminkey = File.read('spec/fixtures/example_key.txt')
    list, _ = ListBuilder.new({email: listname, fingerprint: nil}, adminaddress, adminkey).run
    expect(File.directory?(list.listdir)).to be true
  end

  it "creates a list-key with all required UIDs" do
    listname = "list-#{rand}@example.org"
    adminaddress = 'schleuder2@example.org'
    adminkey = File.read('spec/fixtures/example_key.txt')
    list, _ = ListBuilder.new({email: listname, fingerprint: nil}, adminaddress, adminkey).run
    uids = list.key.uids.map(&:email)
    expect(uids).to include(list.email)
    expect(uids).to include(list.request_address)
    expect(uids).to include(list.owner_address)
  end

  it "subscribes the adminaddress and imports the adminkey" do
    listname = "list-#{rand}@example.org"
    adminaddress = 'schleuder2@example.org'
    adminkey = File.read('spec/fixtures/example_key.txt')
    list, _ = ListBuilder.new({email: listname, fingerprint: nil}, adminaddress, adminkey).run
    subscription_emails = list.subscriptions.map(&:email)
    keys_emails = list.usable_keys.map(&:uids).flatten.map(&:email)
    expect(subscription_emails).to eq [adminaddress]
    expect(keys_emails).to include(adminaddress)
  end
end
