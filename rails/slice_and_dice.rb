# Alters ActiveRecord's condition handling to allow conditions specified as a hash
# of predicates, e.g:
#
#   User.find :first, :conditions => {:name => 'Tom'}
#   Task.find :all, :conditions => {:owner_id => 12}
#
# In addition to these simple equality conditions, other more complex conditions
# can be specified without recourse to SQL:
#
#   User.find :first, :conditions => {:post_count_more_than => 20}
#   Task.find :all, :conditions => {:description_contains => 'london'}
#
# As well as finder methods, this condition syntax also works with scoping,
# calculations and other areas where normal active record conditions
# can be used

class ActiveRecord::Base
  class << self
    alias :sanitize_sql_without_condition_hash :sanitize_sql
  end
  
  def self.sanitize_sql(hash)
    if hash.is_a?(Hash)
      condition = hash.keys.collect{|key| build_condition(key, hash[key])}.join(" AND ")
    else
      sanitize_sql_without_condition_hash(hash)
    end
  end
  
  def self.build_condition(key, argument)
    # TODO needs IN and _all -- and does it handle nil well?
    attribute, condition = split_attribute_and_condition(key)
    fragment = case condition
      when :more_than then ["> ?", argument]
      when :less_than then ["< ?", argument]
      when :not_less_than then [">= ?", argument]
      when :not_more_than then ["<= ?", argument]
      when :starts_with then ["LIKE ?", "#{argument}%"]
      when :ends_with then ["LIKE ?", "%#{argument}"]
      when :icontains, :includes, :contains then ["LIKE ?", "%#{argument}%"] # todo contains better
      when :doesnt_start_with then ["NOT LIKE ?", "#{argument}%"]
      when :doesnt_end_with then ["NOT LIKE ?", "%#{argument}"]
      when :doesnt_contain then ["NOT LIKE ?", "%#{argument}%"]
      else [attribute_condition(argument), argument] # ignores equals, which just gets passed down as normal
    end
    
    "#{table_name}.#{connection.quote_column_name(attribute)} #{sanitize_sql_without_condition_hash(fragment)}"
  end

  def self.find_by conditions, options = {}
    print 'here!'
    new_conditions = self.sanitize_sql(given_conditions)
    raise if options[:conditions]
    options[:conditions] = new_conditions
    self.find :first, how_many, options
  end


  def self.split_attribute_and_condition(key)
    return [key.to_s.sub(/_(more_than|less_than|equals|not_more_than|not_less_than|starts_with|ends_with|doesnt_start_with|doesnt_end_with|icontains|contains|includes|doesnt_contain)$/, ""), $1 ? $1.to_sym : :equals]
  end
end

