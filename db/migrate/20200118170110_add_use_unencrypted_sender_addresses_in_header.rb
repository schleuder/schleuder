class AddUseUnencryptedSenderAddressesInHeader < ActiveRecord::Migration
  def up
    if ! column_exists?(:lists, :use_unencrypted_sender_addresses_in_header)
      add_column :lists, :use_unencrypted_sender_addresses_in_header, :boolean, default: false
    end
  end

  def down
    remove_column(:lists, :use_unencrypted_sender_addresses_in_header)
  end
end
