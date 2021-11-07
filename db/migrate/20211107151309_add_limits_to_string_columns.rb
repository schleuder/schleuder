# It seems, the change to ActiveRecord >= 6.0 makes this necessary.
# Without doing this, the auto-generated database schema file would drop
# these limits, if running migrations.
#
# In contrast to other migrations, only a 'forward' method is provided, a
# mechanism to 'reverse' is not. Given the nature of this migration, the later
# is not really required.
#
# This has been an upstream issue for quite some time. For details, see
# https://github.com/rails/rails/issues/19001.

class AddLimitsToStringColumns < ActiveRecord::Migration[6.0]
  class Lists < ActiveRecord::Base
  end

  class Subscriptions < ActiveRecord::Base
  end

  def up
    [Lists, Subscriptions].each do |table|
      string_columns = table.columns.select { |column| column.type == :string }.map(&:name)

      string_columns.each do |column_name|
        change_column :"#{table.table_name}", :"#{column_name}", :string, :limit => 255
      end
    end
  end
end
