# Since ActiveRecord >= 6.0, the SQLite3 connection adapter relies on boolean
# serialization to use 1 and 0, but does not natively recognize 't' and 'f' as
# booleans were previously serialized.
#
# Accordingly, this migration handles conversion of both column defaults and
# stored data provided by a user.
#
# In contrast to other migrations, only a 'forward' method is provided, a
# mechanism to 'reverse' is not. Given the nature of this migration, the later
# is not really required.
#
# Unfortunately, we missed this breaking change when bumping ActiveRecord to >=
# 6.0 in Schleuder version 4.0. This caused quite some work upstream, but also
# in downstream environments and, last but not least, at the side of users.
#
# We should extend our CI to explicitly test, and ensure things work as
# expected, if running a Schleuder setup in real world. As of now, we don't
# ensure data provided by a user in Schleuder version x still works after
# upgrading to version y.

class ChangeBooleanValuesToIntegers < ActiveRecord::Migration[6.0]
  class Lists < ActiveRecord::Base
  end

  class Subscriptions < ActiveRecord::Base
  end

  def up
    [Lists, Subscriptions].each do |table|
      unless table.connection.is_a?(ActiveRecord::ConnectionAdapters::SQLite3Adapter)
        return
      end

      bool_columns_defaults = table.columns.select { |column| column.type == :boolean }.map{ |column| [column.name, column.default] }

      bool_columns_defaults.each do |column_name, column_default|
        column_bool = ActiveRecord::Type::Boolean.new.deserialize(column_default)
        
        change_column_default :"#{table.table_name}", :"#{column_name}", column_bool
        
        table.where("#{column_name} = 'f'").update_all("#{column_name}": 0)
        table.where("#{column_name} = 't'").update_all("#{column_name}": 1)
      end
    end
  end
end
