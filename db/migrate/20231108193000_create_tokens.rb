class CreateTokens < ActiveRecord::Migration[6.1]
  def up
    create_table :auth_tokens do |t|
      t.timestamps
      t.string :value
      t.string :email
    end
    add_index :auth_tokens, [:value, :email], unique: true
  end

  def down
    drop_table(:auth_tokens)
  end
end
