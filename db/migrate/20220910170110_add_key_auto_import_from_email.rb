class AddKeyAutoImportFromEmail < ActiveRecord::Migration[7.1]
  def up
    if ! column_exists?(:lists, :key_auto_import_from_email)
      add_column :lists, :key_auto_import_from_email, :boolean, default: false
    end
  end

  def down
    remove_column(:lists, :key_auto_import_from_email)
  end
end
