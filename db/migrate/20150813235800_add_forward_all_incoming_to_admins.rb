class AddForwardAllIncomingToAdmins < ActiveRecord::Migration
  def change
    add_column :lists, :forward_all_incoming_to_admins, :boolean, default: false
  end
end
