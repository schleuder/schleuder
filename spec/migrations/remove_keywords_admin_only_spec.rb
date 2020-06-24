require 'spec_helper'

describe 'RemoveKeywordsAdminOnly ' do
  let(:migrations) { ActiveRecord::Migration[5.2].new.migration_context.migrations }
  let(:migration_under_test) { 20190222014121 }
  let(:previous_migration) { 20190222014120 }

  after(:each) do
    ActiveRecord::Migrator.new(:up, migrations).migrate
    List.reset_column_information
  end

  describe 'up' do
    it 'translates admin-only:add-key to subscriber_permissions' do
      ActiveRecord::Migrator.new(:down, migrations, previous_migration).migrate
      list_klass = create_list_klass
      mylist = list_klass.create(keywords_admin_only: %w[add-key])

      ActiveRecord::Migrator.new(:up, migrations, migration_under_test).migrate
      mylist.reload

      expect(mylist.subscriber_permissions).to eql({'view-subscriptions'=>true, 'add-subscriptions'=>true, 'delete-subscriptions'=>true, 'view-keys'=>true, 'add-keys'=>false, 'delete-keys'=>true, 'view-list-config'=>true, 'resend-encrypted'=>true, 'resend-unencrypted'=>true})
    end

    it 'translates admin-only:resend configuration to subscriber_permissions' do
      ActiveRecord::Migrator.new(:down, migrations, previous_migration).migrate
      list_klass = create_list_klass
      mylist = list_klass.create(keywords_admin_only: %w[resend])

      ActiveRecord::Migrator.new(:up, migrations, migration_under_test).migrate
      mylist.reload

      expect(mylist.subscriber_permissions).to eql({'view-subscriptions'=>true, 'add-subscriptions'=>true, 'delete-subscriptions'=>true, 'view-keys'=>true, 'add-keys'=>true, 'delete-keys'=>true, 'view-list-config'=>true, 'resend-encrypted'=>true, 'resend-unencrypted'=>false})
    end

    it 'translates admin-only:resend-encrypted-only configuration to subscriber_permissions' do
      ActiveRecord::Migrator.new(:down, migrations, previous_migration).migrate
      list_klass = create_list_klass
      mylist = list_klass.create(keywords_admin_only: %w[resend-encrypted-only])

      ActiveRecord::Migrator.new(:up, migrations, migration_under_test).migrate
      mylist.reload

      expect(mylist.subscriber_permissions).to eql({'view-subscriptions'=>true, 'add-subscriptions'=>true, 'delete-subscriptions'=>true, 'view-keys'=>true, 'add-keys'=>true, 'delete-keys'=>true, 'view-list-config'=>true, 'resend-encrypted'=>false, 'resend-unencrypted'=>true})
    end

    it 'translates admin-only:resend,resend-encrypted-only configuration to subscriber_permissions' do
      ActiveRecord::Migrator.new(:down, migrations, previous_migration).migrate
      list_klass = create_list_klass
      mylist = list_klass.create(keywords_admin_only: %w[resend resend-encrypted-only])

      ActiveRecord::Migrator.new(:up, migrations, migration_under_test).migrate
      mylist.reload

      expect(mylist.subscriber_permissions).to eql({'view-subscriptions'=>true, 'add-subscriptions'=>true, 'delete-subscriptions'=>true, 'view-keys'=>true, 'add-keys'=>true, 'delete-keys'=>true, 'view-list-config'=>true, 'resend-encrypted'=>false, 'resend-unencrypted'=>false})
    end

    it 'translates admin-only:resend-cc-encrypted-only,resend-unencrypted configuration to subscriber_permissions' do
      ActiveRecord::Migrator.new(:down, migrations, previous_migration).migrate
      list_klass = create_list_klass
      mylist = list_klass.create(keywords_admin_only: %w[resend-cc-encrypted-only resend-unencrypted])

      ActiveRecord::Migrator.new(:up, migrations, migration_under_test).migrate
      mylist.reload

      expect(mylist.subscriber_permissions).to eql({'view-subscriptions'=>true, 'add-subscriptions'=>true, 'delete-subscriptions'=>true, 'view-keys'=>true, 'add-keys'=>true, 'delete-keys'=>true, 'view-list-config'=>true, 'resend-encrypted'=>false, 'resend-unencrypted'=>false})
    end
  end

  describe 'down' do
    it 'translates add-keys:false to keywords_admin_only' do
      ActiveRecord::Migrator.new(:up, migrations, migration_under_test).migrate
      list_klass = create_list_klass
      mylist = list_klass.create(subscriber_permissions: { 'add-keys': false })

      ActiveRecord::Migrator.new(:down, migrations, previous_migration).migrate
      list_klass = create_list_klass
      mylist = list_klass.find(mylist.id)

      expect(mylist.keywords_admin_only).to eql(%w[add-key fetch-key])
    end

    it 'translates resend-encrypted:false to keywords_admin_only' do
      ActiveRecord::Migrator.new(:up, migrations, migration_under_test).migrate
      list_klass = create_list_klass
      mylist = list_klass.create(subscriber_permissions: { 'resend-encrypted': false })

      ActiveRecord::Migrator.new(:down, migrations, previous_migration).migrate
      list_klass = create_list_klass
      mylist = list_klass.find(mylist.id)

      expect(mylist.keywords_admin_only).to eql(%w[resend-encrypted-only resend-cc-encrypted-only])
    end

    it 'translates resend-unencrypted:false to keywords_admin_only' do
      ActiveRecord::Migrator.new(:up, migrations, migration_under_test).migrate
      list_klass = create_list_klass
      mylist = list_klass.create(subscriber_permissions: { 'resend-unencrypted': false })

      ActiveRecord::Migrator.new(:down, migrations, previous_migration).migrate
      list_klass = create_list_klass
      mylist = list_klass.find(mylist.id)

      expect(mylist.keywords_admin_only).to eql(%w[resend resend-unencrypted resend-cc resend-cc-unencrypted])
    end
  end


  def create_list_klass
    Class.new(ActiveRecord::Base) do
      self.table_name = 'lists'
      self.serialize :keywords_admin_only, JSON
      self.serialize :subscriber_permissions, JSON
    end
  end
end
