require 'spec_helper'

describe KeywordHandlers::AccountManagement do
  describe '.get_new_password' do
    it 'sets a new password for an account' do
      mail = Mail.new
      mail.list = create(:list)
      subscription, _ = mail.list.subscribe('subscription@example.net', 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE', false)
      mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
      mail.instance_variable_set('@signing_key', mail.list.key('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE'))
      account = create(:account, email: subscription.email)
      password_digest = account.password_digest

      output = KeywordHandlers::AccountManagement.new(mail: mail, arguments: []).get_new_password

      expect(output).to match("This is the new password for the account of #{subscription.email}: .*")
      expect(password_digest).not_to eql(account.reload.password_digest)
    end
  end

  describe '.get_new_password_for' do
    it 'rejects message from non-admins, without changing the password of the account' do
      mail = Mail.new
      mail.list = create(:list)
      subscription, _ = mail.list.subscribe('subscription@example.net', 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE', false)
      mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
      mail.instance_variable_set('@signing_key', mail.list.key('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE'))
      account = create(:account, email: subscription.email)
      password_digest = account.password_digest

      output = KeywordHandlers::AccountManagement.new(mail: mail, arguments: [subscription.email]).get_new_password_for

      expect(output).to eql("Error: Only admins may use this keyword.\n\nTo request setting a new password for your own account use X-GET-NEW-PASSWORD.\n")
      expect(password_digest).to eql(account.reload.password_digest)
    end

    it 'sets and sends a new password if requested by a list-admin' do
      mail = Mail.new
      mail.list = create(:list)
      subscription, _ = mail.list.subscribe('subscription@example.net', 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE', true)
      mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
      mail.instance_variable_set('@signing_key', mail.list.key('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE'))
      account = create(:account, email: subscription.email)
      password_digest = account.password_digest

      output = KeywordHandlers::AccountManagement.new(mail: mail, arguments: []).get_new_password_for

      expect(output).to match('Error: this keyword requires exactly one argument: The email address for which the new password should be set.')
      expect(password_digest).to eql(account.reload.password_digest)
    end

    it 'rejects messages without keyword arguments, without changing the password of the account' do
      mail = Mail.new
      mail.list = create(:list)
      subscription, _ = mail.list.subscribe('subscription@example.net', 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE', true)
      mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
      mail.instance_variable_set('@signing_key', mail.list.key('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE'))
      account = create(:account, email: subscription.email)
      password_digest = account.password_digest

      output = KeywordHandlers::AccountManagement.new(mail: mail, arguments: []).get_new_password_for

      expect(output).to match('Error: this keyword requires exactly one argument: The email address for which the new password should be set.')
      expect(password_digest).to eql(account.reload.password_digest)
    end

    it 'sets and sends a new password for the requested account if requested by a list-admin' do
      mail = Mail.new
      mail.list = create(:list)
      admin, _ = mail.list.subscribe('admin@example.net', '59C71FB38AEE22E091C78259D06350440F759BD3', true)
      subscription, _ = mail.list.subscribe('subscription@example.net', 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE', false)
      mail.instance_variable_set('@signing_key', mail.list.key('59C71FB38AEE22E091C78259D06350440F759BD3'))
      admin_account = create(:account, email: admin.email)
      admin_password_digest = admin_account.password_digest
      subscription_account = create(:account, email: subscription.email)
      subscription_password_digest = subscription_account.password_digest

      output = KeywordHandlers::AccountManagement.new(mail: mail, arguments: [subscription.email]).get_new_password_for

      expect(output).to match(/^This is the new password for the account of #{subscription.email}: .{10,12}$/)
      expect(subscription_password_digest).not_to eql(subscription_account.reload.password_digest)
      expect(admin_password_digest).to eql(admin_account.reload.password_digest)
    end

    it 'sets and sends a new password for the requested account if requested by an api_superadmin' do
      mail = Mail.new
      mail.list = create(:list)
      subscription1, _ = mail.list.subscribe('subscription1@example.net', 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE', false)
      subscription2, _ = mail.list.subscribe('subscription2@example.net', '59C71FB38AEE22E091C78259D06350440F759BD3', false)
      superadmin_account = create(:account, email: subscription1.email, api_superadmin: true)
      superadmin_password_digest = superadmin_account.password_digest
      subscription_account = create(:account, email: subscription2.email)
      subscription_password_digest = subscription_account.password_digest
      mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
      mail.instance_variable_set('@signing_key', mail.list.key('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE'))

      output = KeywordHandlers::AccountManagement.new(mail: mail, arguments: [subscription2.email]).get_new_password_for

      expect(output).to match(/^This is the new password for the account of #{subscription2.email}: .{10,12}$/)
      expect(subscription_password_digest).not_to eql(subscription_account.reload.password_digest)
      expect(superadmin_password_digest).to eql(superadmin_account.reload.password_digest)
    end

    it 'rejects to set a new password for an email address that is not subscribed to the list' do
      mail = Mail.new
      mail.list = create(:list)
      admin, _ = mail.list.subscribe('admin@example.net', 'C4D60F8833789C7CAA44496FD3FFA6613AB10ECE', true)
      mail.list.import_key(File.read('spec/fixtures/example_key.txt'))
      mail.instance_variable_set('@signing_key', mail.list.key('C4D60F8833789C7CAA44496FD3FFA6613AB10ECE'))
      account = create(:account, email: admin.email)
      password_digest = account.password_digest

      error = nil
      begin
        output = KeywordHandlers::AccountManagement.new(mail: mail, arguments: ['notsubscribed@example.net']).get_new_password_for
      rescue => exc
        error = exc
      end

      expect(output).to be_blank
      expect(error).to be_a Schleuder::Errors::SubscriptionNotFound
      expect(password_digest).to eql(account.reload.password_digest)
      expect(Account.count).to eql(1)
    end
  end
end
