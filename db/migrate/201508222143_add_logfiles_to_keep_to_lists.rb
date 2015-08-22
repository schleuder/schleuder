class AddLogfilesToKeepToLists < ActiveRecord::Migration
  def change
    add_column :lists, :logfiles_to_keep, :integer, default: 2
  end
end
