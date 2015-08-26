class StripGpgPassphrase < ActiveRecord::Migration
  def up
    remove_column :lists, :gpg_passphrase
  end

  def down
    add_column :lists, :gpg_passphrase, :string
  end
end
