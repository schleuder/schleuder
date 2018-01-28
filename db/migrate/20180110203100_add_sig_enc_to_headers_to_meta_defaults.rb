class AddSigEncToHeadersToMetaDefaults < ActiveRecord::Migration
  def up
    change_column_default :lists, :headers_to_meta, '["from", "to", "cc", "date", "sig", "enc"]'
    # Use a temporary class-definition to be independent of the
    # complexities of the actual class.
    class List < ActiveRecord::Base; end
    List.reset_column_information
    List.find_each do |list|
      if (list.headers_to_meta & ['sig', 'enc']).empty?
        list.update(headers_to_meta: list.headers_to_meta + ['sig', 'enc'])
      end
    end
  end

  def down
    change_column_default :lists, :headers_to_meta, '["from", "to", "cc", "date"]'
    # Use a temporary class-definition to be independent of the
    # complexities of the actual class.
    class List < ActiveRecord::Base; end
    List.reset_column_information
    List.find_each do |list|
      list.update(headers_to_meta: list.headers_to_meta - ['enc','sig'])
    end
  end
end
