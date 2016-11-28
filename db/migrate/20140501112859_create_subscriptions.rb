class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.integer :list_id
      t.string  :email
      t.string  :fingerprint
      t.boolean :admin, default: false
      t.boolean :delivery_disabled, default: false
      t.timestamps
    end

    add_index :subscriptions, :list_id
    add_index :subscriptions, [:email, :list_id], unique: true
  end
end
