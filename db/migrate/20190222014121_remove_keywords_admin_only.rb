class RemoveKeywordsAdminOnly < ActiveRecord::Migration[5.2]
  KEYWORDS_PERMISSIONS_MAP = {
      ['list-keys', 'get-key'] => 'view-keys',
      ['add-key', 'fetch-key'] => 'add-keys',
      ['delete-key']           => 'delete-keys',
      ['list-subscriptions']   => 'view-subscriptions',
      ['subscribe', 'set-fingerprint', 'unset-fingerprint'] => 'add-subscriptions',
      ['unsubscribe']          => 'delete-subscriptions',
      ['get-logfile']          => 'view-list-config',
      ['resend-encrypted-only', 'resend-cc-encrypted-only'] => 'resend-encrypted',
      ['resend', 'resend-unencrypted', 'resend-cc', 'resend-cc-unencrypted'] => 'resend-unencrypted'
    }

  def up
    list_klass = create_list_klass
    list_klass.reset_column_information
    list_klass.find_each do |list|
      # By default open up, then disallow based on keywords_admin_only.
      sub_permissions = list.subscriber_permissions
      sub_permissions["view-subscriptions"] = true
      sub_permissions["add-subscriptions"] = true
      sub_permissions["delete-subscriptions"] = true
      sub_permissions["view-keys"] = true
      sub_permissions["add-keys"] = true
      sub_permissions["delete-keys"] = true
      sub_permissions["view-list-config"] = true
      sub_permissions["resend-encrypted"] = true
      sub_permissions["resend-unencrypted"] = true
      
      list.keywords_admin_only.each do |keyword|
        match = KEYWORDS_PERMISSIONS_MAP.find { |k,v| k.include?(keyword) }
        if match.present?
          permission = match.last
          sub_permissions[permission] = false
        end
      end
      list.update_attribute(:subscriber_permissions, sub_permissions)
    end

    remove_column :lists, :keywords_admin_only
  end

  def down
    add_column :lists, :keywords_admin_only, :text, default: '["subscribe", "unsubscribe", "delete-key"]'

    list_klass = create_list_klass
    list_klass.reset_column_information
    list_klass.find_each do |list|
      keywords_admin_only = []
      list.subscriber_permissions.each do |permission, value|
        if value == false
          keywords = KEYWORDS_PERMISSIONS_MAP.invert[permission]
          if keywords.present?
            keywords_admin_only += keywords
          end
        end
      end

      list.update_attribute(:keywords_admin_only, keywords_admin_only)
    end
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
