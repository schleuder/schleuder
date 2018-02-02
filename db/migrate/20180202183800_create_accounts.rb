class CreateAccounts < ActiveRecord::Migration
  def up
    create_table :accounts do |t|
      t.string :email, unique: true, null: false
      t.string :password
    end

    add_index :accounts, :email
  end

  def down
    drop_table(:accounts)
  end
end
