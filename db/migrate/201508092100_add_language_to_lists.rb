class AddLanguageToLists < ActiveRecord::Migration
  def change
    add_column :lists, :language, :string, default: 'en'
  end
end
