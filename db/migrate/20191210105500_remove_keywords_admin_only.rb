class RemoveKeywordsAdminOnly < ActiveRecord::Migration[5.2]
  def up
    remove_column :lists, :keywords_admin_only
  end

  def down
    add_column :lists, :keywords_admin_only, :text, default: "[\"subscribe\", \"unsubscribe\", \"delete-key\"]"
  end
end
