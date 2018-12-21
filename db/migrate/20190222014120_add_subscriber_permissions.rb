class AddSubscriberPermissions < ActiveRecord::Migration[5.2]
  def up
    add_column :lists, :subscriber_permissions, :text, default: '{ "view-subscriptions": true, "add-subscriptions": false, "delete-subscriptions": false, "view-keys": true, "add-keys": true, "delete-keys": false, "view-list-config": false }'
  end

  def down
    remove_column :lists, :subscriber_permissions
  end
end
