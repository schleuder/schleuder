class CreateAccounts < ActiveRecord::Migration
  def up
    create_table :accounts do |t|
      t.string :email, null: false
      t.string :password
    end

    add_index :accounts, :email, unique: true
  end

  def down
    drop_table(:accounts)
  end
end
