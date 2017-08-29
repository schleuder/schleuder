class AddInternalFooterToList < ActiveRecord::Migration
  def change
    add_column :lists, :internal_footer, :text, default: ''
  end
end
