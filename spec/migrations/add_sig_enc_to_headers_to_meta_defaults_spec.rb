require 'spec_helper'

describe 'AddSigEncToHeadersToMetaDefaults' do
  let(:migrations_paths) { 'db/migrate' }
  let(:migration_under_test) { 20180110203100 }
  let(:previous_migration) { 20170713215059 }

  describe 'up' do
    it 'sets the column defaults' do
      ActiveRecord::Migrator.migrate(migrations_paths, previous_migration)
      list_klass = create_list_klass
      list_klass.reset_column_information

      ActiveRecord::Migrator.migrate(migrations_paths, migration_under_test)
      list_klass.reset_column_information

      expect(list_klass.column_defaults['headers_to_meta']).to eql(["from", "to", "cc", "date", "sig", "enc"])
    end

    it 'adds sig and enc to headers_to_meta for lists wihtout the attributes' do
      ActiveRecord::Migrator.migrate(migrations_paths, previous_migration)
      list_klass = create_list_klass
      list = create(:list, headers_to_meta: list_klass.column_defaults['headers_to_meta'])

      expect(list.headers_to_meta).not_to include('enc', 'sig')

      ActiveRecord::Migrator.migrate(migrations_paths, migration_under_test)
      list_klass.reset_column_information
      list.reload

      expect(list.headers_to_meta).to include('enc', 'sig')
    end

    it 'does not add sig and enc to headers to meta if the attributes already exist' do
      headers_to_meta_including_sig_and_enc = ["from", "to", "cc", "date", "sig", "enc"]
      ActiveRecord::Migrator.migrate(migrations_paths, previous_migration)
      list_klass = create_list_klass
      list = create(:list, headers_to_meta: headers_to_meta_including_sig_and_enc)

      expect(list.headers_to_meta).to eql headers_to_meta_including_sig_and_enc

      ActiveRecord::Migrator.migrate(migrations_paths, migration_under_test)
      list_klass.reset_column_information
      list.reload

      expect(list.headers_to_meta).to eql headers_to_meta_including_sig_and_enc
    end
  end

  describe 'down' do
    it 'sets the column defaults' do
      ActiveRecord::Migrator.migrate(migrations_paths, migration_under_test)
      list_klass = create_list_klass
      list_klass.reset_column_information

      ActiveRecord::Migrator.migrate(migrations_paths, previous_migration)
      list_klass.reset_column_information

      expect(list_klass.column_defaults['headers_to_meta']).to eql(["from", "to", "cc", "date"])
    end

    it 'removes sig and enc from headers_to_meta from existing lists' do
      ActiveRecord::Migrator.migrate(migrations_paths, migration_under_test)
      list_klass = create_list_klass
      list_klass.reset_column_information
      list = create(:list, headers_to_meta: list_klass.column_defaults['headers_to_meta'])

      expect(list.headers_to_meta).to include('enc', 'sig')

      ActiveRecord::Migrator.migrate(migrations_paths, previous_migration)
      list_klass.reset_column_information
      list.reload

      expect(list.headers_to_meta).not_to include('enc', 'sig')
    end
  end

  def create_list_klass
    Class.new(ActiveRecord::Base) do
      self.table_name = 'lists'
      self.serialize :headers_to_meta, JSON
    end
  end
end
