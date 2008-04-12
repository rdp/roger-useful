# Alters ActiveRecord's condition handling to allow conditions specified as a hash and English!
# take out _'s
# allow for names themselves with/without underscores [does this work?]
# name doesnt include needs help
# of predicates, e.g:
#
#   User.find :first, :conditions => {:name => 'Tom'}
#   Task.find :all, :conditions => {:owner_id => 12}
#
# In addition to these simple equality conditions, other more complex conditions
# can be specified without recourse to SQL:
#
#   User.find :first, :conditions => {:post_count_gt => 20}
#   Task.find :all, :conditions => {:description_contains => 'london'}
#
# As well as finder methods, this condition syntax also works with scoping,
# calculations and other areas where normal active record conditions
# can be used
# note that we can't use it with 'normal' :conditions => this, at least currently
# note you can optionally _all (i.e. :doesnt_contain_all => ['abc','def'])
# note you can optionally have a final suffix ? (i.e. :contains? => 'abc')
# note that if you pass it an array, it defaults to 'OR'
# i.e. :contains => ['abc', 'def'] ==> contains 'abc' OR contains 'def'
# to use and add _all to the end
# :contains_all => ['abc', 'def'] ==> contains 'abc' AND contains 'def'
# negatives works, too :doesnt_contain => ['ghi', 'jkl'] ==> NOT contains 'ghi' and NOT contains 'jkl'

# todo check various
# todo negation abilities (test if I use them)
# todo allow spaces or _
# todo add !=, =, ==, <, >, <= 
# todo -- do I allow for retardedness supersets?
# todo allow for 'sensitive' and space after
=begin
#doctest Check that 1 + 1 = 2
>> 1 + 1
=> 2
>> 2 + 3
=> 5
=end
class ActiveRecord::Base
=begin
#setup_doctest once_per_file
require 'activerecord'
class TestConnection
  def quote_column_name name
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
=end
  
  # todo: check if it works with custom foreign keys
  def self.hash_to_conditions_string(hash)
    hash.keys.collect{|key| 
      if hash[key].class == Array
        attribute, is_case_sensitive, condition, optional_multiples_style = split_attribute_and_condition(key) # grab its multiples style
        if condition.to_s =~ /doesnt/
          optional_multiples_style = optional_multiples_style == :all ? :any : :all # negate it, to keep the logic right for negatives
        end
        
        interiors = hash[key].map{|sub_key| 
          build_single_condition(key, sub_key)
        }
        
        if optional_multiples_style == :all
          raise 'unsupported style for _all, as it would seem exclusive so to not make sense' if [:is, :equals, :starts_with, :begins_with, :ends_with].include? condition
          interiors.join(" AND ")
        else # :any, :in, or none specified, they just gave us an array.  Note that we use 'OR' instead of IN (a,b,c) since it's the equivalent, really, and then we don't have to worry about special cases, like a REGEX or what not.
          # we should never raise if we get here, since we're only widening the scope
          
      			' (' << interiors.join(" OR ") << ') '
        end
        
      else
        build_single_condition(key, hash[key])
      end
    }.join(" AND ")
  end
  # todo: allow for it to come in as a string or a symbol
  # could do: make it work with :conditions => this again 
=begin
#doctest work with non underscore
>> TestAR.build_single_condition('test column name equals',3)
=> " test_ars.test_column_name = 3"
>> TestAR.build_single_condition('test_column_name equals',3)
=> " test_ars.test_column_name = 3"
=end
  def self.build_single_condition(key, argument)
    attribute, is_case_sensitive, condition, optional_multiples_style = split_attribute_and_condition(key)
    
    
    unless column_names.include? attribute
      # allow for them to pass in an attribute
      if argument.class.ancestors.include? ActiveRecord::Base and self.column_names.include? (attribute + '_id') and argument.class != Array # last one to double check if they pass somethign like :order => user.orders, which we don't handle yet
        # assume they are trying to use a shortcut :order => order_instance and really want its id
        # could do -- :order => instance check if the class matches expected  
        attribute += '_id'
        argument = argument.id
      elsif column_names.include? (attribute.gsub(' ', '_')) # test if replacing spaces with _'s fixes it, to allow for natural queries
        attribute = attribute.gsub(' ', '_')
      end
      raise 'unknown DB column -- possible syntax error' + attribute unless self.column_names.include? attribute
    end
    
    fragment = case condition
      when :gt then ["> ?", argument]
      when :less_than, :lt then ["< ?", argument]
      when :gte then [">= ?", argument]
      when :lte then ["<= ?", argument]
      when :begins_with, :starts_with then ["LIKE ?", "#{argument}%"]
      when :ends_with then ["LIKE ?", "%#{argument}"]
      when :contains, :includes then ["LIKE ?", "%#{argument}%"]
      when :doesnt_start_with then ["NOT LIKE ?", "#{argument}%"]
      when :doesnt_end_with then ["NOT LIKE ?", "%#{argument}"]
      when :doesnt_contain then ["NOT LIKE ?", "%#{argument}%"]
      when :matches then ["REGEXP ?", argument.gsub(')', '\\)').gsub(')', '\\)')]# TODO sanitize better
    else [attribute_condition(argument), argument] # ignores equals, etc., which just gets passed down as normal, and work with nil (!)
    end
    
    case_sensitive_addition = ' BINARY ' if is_case_sensitive
    
    "#{case_sensitive_addition} #{table_name}.#{connection.quote_column_name(attribute)} #{sanitize_sql(fragment)}"
  end
  
  def self.find_where conditions, options = {} # I guess the original author overcame this by just sanitizing sql on its way down or something (?) this need help TODO decide on scope of this :)
    new_conditions = self.hash_to_conditions_string(conditions)
    options[:conditions] ||= ''
    options[:conditions] = ' ' << new_conditions
    options[:limit] ||= 2
    all = self.find :all, options
    print "MORE THAN ONE EXISTED!" if all.length > 1
    all[0]
  end
  
  def self.all_where conditions, options = {}
    new_conditions = self.hash_to_conditions_string(conditions)
    options[:conditions] ||= ''
    options[:conditions] = ' ' << new_conditions
    self.find :all, options
  end
  
=begin
#doctest should split a name+condition into column_name, case_sensitivity, condition, multiples_style
>>  ActiveRecord::Base.split_attribute_and_condition('name_includes')
=> ["name", nil, :includes, nil]
>> ActiveRecord::Base.split_attribute_and_condition 'email_address scontains'
=> ["email_address", :sensitive, :contains, nil]
>> ActiveRecord::Base.split_attribute_and_condition 'email_address scontains all'
=> ["email_address", :sensitive, :contains, :all]
>> ActiveRecord::Base.split_attribute_and_condition 'email_address contains all'
=> ["email_address", nil, :contains, :all]
>> ActiveRecord::Base.split_attribute_and_condition 'email_address contains any'
=> ["email_address", nil, :contains, :any]
class Post < ActiveRecord::Base
  belongs_to :user
  has_and_belongs_to_many :tags
end
=end
  
  def self.split_attribute_and_condition(key) 
    # also allows for _any and _all and _in suffixes (_in being _any)
    # also allows for an ending ? like :includes? => 'abc'
    # also allows for an s prefix, i.e. _sstarts_with => 'ABC'  # for case sensitive
    # TODO allow for anything to have 'not' at the beginning (?) or doesnt? -- not yet
    column_name = key.sub(/(_|__| )(|s|sensitive)(| )(|gt|greater[_ ]than|less[ _]than|lt|is|equals|lte|gte|starts[ _]with|begins[ _]with|ends[ _]with|doesnt[ _]start[ _]with|doesnt[ _]end[ _]with|contains|include.|doesnt_contain|matches)(|_| )(|any|all|in)(|\?)(| )$/, "")
    sensitivity = $2.blank? ? nil : :sensitive
    multiples_style =  $6.blank? ? nil : $6.to_sym 
    condition = !$4.blank? ? $4.gsub(' ', '_').to_sym : :equals
    return column_name, sensitivity, condition, multiples_style
  end
end
# todo within
# todo is
# todo does doesnt_start_with_all work? it should err, I think

class ActiveRecord::Base
  class << self
    def first options = {}
      return self.find :first, options
    end
    alias :fw :find_where
    alias :aw :all_where
    alias :where :find_where
  end
end
