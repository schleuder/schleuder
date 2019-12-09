class RemoveKeywordsAdminOnly < ActiveRecord::Migration[5.2]
  def up
    list_klass = create_list_klass
    list_klass.reset_column_information
    list_klass.find_each do |list|
      sub_permissions = list.subscriber_permissions
      list.keywords_admin_only.each do |keyword|
        case keyword
          when "list-keys", "get-key" then sub_permissions["view-keys"] = false
          when "add-key", "fetch-key" then sub_permissions["add-keys"] = false
          when "delete-key"           then sub_permissions["delete-keys"] = false
          when "list-subscriptions"   then sub_permissions["view-subscriptions"] = false
          when "subscribe"            then sub_permissions["add-subscriptions"] = false
          when "unsubscribe"          then sub_permissions["delete-subscriptions"] = false
          # "set-fingerprint" and "unset-fingerprint" are not listed here because they are governed by "add-subscriptions"
          when "get-logfile"          then sub_permissions["view-list-config"] = false
        end
      end
      list.update_attribute(:subscriber_permissions, sub_permissions)
    end

    remove_column :lists, :keywords_admin_only
  end

  def down
    add_column :lists, :keywords_admin_only, :text, default: "[\"subscribe\", \"unsubscribe\", \"delete-key\"]"
  end

  def create_list_klass
    # Use a temporary class-definition to be independent of the
    # complexities of the actual class.
    Class.new(ActiveRecord::Base) do
      self.table_name = 'lists'
      self.serialize :keywords_admin_only, JSON
      self.serialize :subscriber_permissions, JSON
    end
  end
end
