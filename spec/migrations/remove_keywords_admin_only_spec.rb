require 'spec_helper'

describe 'RemoveKeywordsAdminOnly ' do
  let(:migration_under_test) { 20190222014121 }
  let(:previous_migration) { 20190222014120 }
  let(:schema_migration) { ActiveRecord::Base.connection.schema_migration }
  let(:migrator) { ActiveRecord::MigrationContext.new("./db/migrate", schema_migration) }

  after(:each) do
    ActiveRecord::Base.connection.schema_cache.clear!
    migrator.up
  end

  describe 'up' do
    it 'migrates as expected' do
      migrator.down(previous_migration)
      expect(migrator.current_version).to eql(previous_migration)

      migrator.up(migration_under_test)
      expect(migrator.current_version).to eql(migration_under_test)
    end

    it 'translates admin-only:add-key to subscriber_permissions' do
      migrator.down(previous_migration)
      list_klass = create_list_klass
      mylist = list_klass.create(keywords_admin_only: %w[add-key])

      migrator.up(migration_under_test)
      mylist.reload

      expect(mylist.subscriber_permissions).to eql({'view-subscriptions'=>true, 'add-subscriptions'=>true, 'delete-subscriptions'=>true, 'view-keys'=>true, 'add-keys'=>false, 'delete-keys'=>true, 'view-list-config'=>true, 'resend-encrypted'=>true, 'resend-unencrypted'=>true})
    end

    it 'translates admin-only:resend configuration to subscriber_permissions' do
      migrator.down(previous_migration)
      list_klass = create_list_klass
      mylist = list_klass.create(keywords_admin_only: %w[resend])

      migrator.up(migration_under_test)
      mylist.reload

      expect(mylist.subscriber_permissions).to eql({'view-subscriptions'=>true, 'add-subscriptions'=>true, 'delete-subscriptions'=>true, 'view-keys'=>true, 'add-keys'=>true, 'delete-keys'=>true, 'view-list-config'=>true, 'resend-encrypted'=>true, 'resend-unencrypted'=>false})
    end

    it 'translates admin-only:resend-encrypted-only configuration to subscriber_permissions' do
      migrator.down(previous_migration)
      list_klass = create_list_klass
      mylist = list_klass.create(keywords_admin_only: %w[resend-encrypted-only])

      migrator.up(migration_under_test)
      mylist.reload

      expect(mylist.subscriber_permissions).to eql({'view-subscriptions'=>true, 'add-subscriptions'=>true, 'delete-subscriptions'=>true, 'view-keys'=>true, 'add-keys'=>true, 'delete-keys'=>true, 'view-list-config'=>true, 'resend-encrypted'=>false, 'resend-unencrypted'=>true})
    end

    it 'translates admin-only:resend,resend-encrypted-only configuration to subscriber_permissions' do
      migrator.down(previous_migration)
      list_klass = create_list_klass
      mylist = list_klass.create(keywords_admin_only: %w[resend resend-encrypted-only])

      migrator.up(migration_under_test)
      mylist.reload

      expect(mylist.subscriber_permissions).to eql({'view-subscriptions'=>true, 'add-subscriptions'=>true, 'delete-subscriptions'=>true, 'view-keys'=>true, 'add-keys'=>true, 'delete-keys'=>true, 'view-list-config'=>true, 'resend-encrypted'=>false, 'resend-unencrypted'=>false})
    end

    it 'translates admin-only:resend-cc-encrypted-only,resend-unencrypted configuration to subscriber_permissions' do
      migrator.down(previous_migration)
      list_klass = create_list_klass
      mylist = list_klass.create(keywords_admin_only: %w[resend-cc-encrypted-only resend-unencrypted])

      migrator.up(migration_under_test)
      mylist.reload

      expect(mylist.subscriber_permissions).to eql({'view-subscriptions'=>true, 'add-subscriptions'=>true, 'delete-subscriptions'=>true, 'view-keys'=>true, 'add-keys'=>true, 'delete-keys'=>true, 'view-list-config'=>true, 'resend-encrypted'=>false, 'resend-unencrypted'=>false})
    end
  end

  describe 'down' do
    it 'translates add-keys:false to keywords_admin_only' do
      migrator.up(migration_under_test)
      list_klass = create_list_klass
      mylist = list_klass.create(subscriber_permissions: { 'add-keys': false })

      migrator.down(previous_migration)
      list_klass = create_list_klass
      mylist = list_klass.find(mylist.id)

      expect(mylist.keywords_admin_only).to eql(%w[add-key fetch-key])
    end

    it 'translates resend-encrypted:false to keywords_admin_only' do
      migrator.up(migration_under_test)
      list_klass = create_list_klass
      mylist = list_klass.create(subscriber_permissions: { 'resend-encrypted': false })

      migrator.down(previous_migration)
      list_klass = create_list_klass
      mylist = list_klass.find(mylist.id)

      expect(mylist.keywords_admin_only).to eql(%w[resend-encrypted-only resend-cc-encrypted-only])
    end

    it 'translates resend-unencrypted:false to keywords_admin_only' do
      migrator.up(migration_under_test)
      list_klass = create_list_klass
      mylist = list_klass.create(subscriber_permissions: { 'resend-unencrypted': false })

      migrator.down(previous_migration)
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
