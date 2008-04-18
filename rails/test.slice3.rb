def dbg; require 'ruby-debug'; debugger; end
require 'activerecord'
class TestConnection # used as a shunt for TestAR
  def quote_column_name name
   name
  end
  def quote_table_name name
   name
  end
  def quote name
    name
  end
end
class TestAR < ActiveRecord::Base
  belongs_to :user
  has_and_belongs_to_many :tags
  # testing shunt here
  def self.column_names
    ['test_column_name']
  end

  def self.connection
    return TestConnection.new
  end

end
# 'real' tests would be nice
class Post < ActiveRecord::Base
  belongs_to :user
  has_and_belongs_to_many :tags
end


