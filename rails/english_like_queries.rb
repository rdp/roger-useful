# Alters ActiveRecord's condition handling to allow conditions specified as a hash and English!
# ltodo: allow where id as number or string
# Note: this project was heavily inspired by django's query syntax
# and took its codebase from the slice_and_dice project [then made it work with english and multiples] 
# allow for names themselves with/without underscores [does this work?] TOTEST
# name doesnt include needs help TOTEST
# of predicates, e.g:
#
#   User.find :first, :conditions => {:name => 'Tom'}
#   Task.find :all, :conditions => {:owner_id => 12}
#
# In addition to these simple equality conditions, other more complex conditions
# can be specified without recourse to SQL:
#
#   User.where {'post_count_gt' => 20}
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

# todo negation abilities  TOTEST
# could do: 'closest match' as a whole new function
=begin
#setup_doctest once_per_file
require 'test.slice3.rb'
=end


 class ActiveRecord::Base 
  # lodo: check if it works with custom foreign keys
=begin 
# doctest joins things together right
>> TestAR.hash_to_conditions_string 'test_column_name equals' => 3
=> " BINARY  test_ars.test_column_name = 3"
>> TestAR.hash_to_conditions_string 'test_column_name is in' => 3
=> " BINARY  test_ars.test_column_name = 3"
>> TestAR.hash_to_conditions_string 'test_column_name is in' => [3,4,5]
=> " ( BINARY  test_ars.test_column_name = 3 OR  BINARY  test_ars.test_column_name = 4 OR  BINARY  test_ars.test_column_name = 5) "
>> TestAR.hash_to_conditions_string 'test_column_name match' => 'abc'
=> " BINARY  test_ars.test_column_name REGEXP abc"
>> TestAR.hash_to_conditions_string 'test_column_name match' => ['abc', 'bbd']
=> " ( BINARY  test_ars.test_column_name REGEXP abc OR  BINARY  test_ars.test_column_name REGEXP bbd) "
>> TestAR.hash_to_conditions_string 'test_column_name doesnt match' => ['abc', 'bbd']
=> "NOT  BINARY  test_ars.test_column_name REGEXP abc AND NOT  BINARY  test_ars.test_column_name REGEXP bbd"
	BtAR.hash_to_conditions_string 'test_column_name doesnt match any' => ['abc', 'bbd']
=> "NOT  BINARY  test_ars.test_column_name REGEXP abc AND NOT  BINARY  test_ars.test_column_name REGEXP bbd"
>> TestAR.hash_to_conditions_string 'test_column_name idoesnt equal any' => ['abc', 'bbd']
RuntimeError: unsupported style for _all, as it would seem exclusive so to not make sense

>> TestAR.hash_to_conditions_string 'test_column_name idoesnt match all' => ['abc', 'bbd']
=> " (NOT  test_ars.test_column_name REGEXP abc OR NOT  test_ars.test_column_name REGEXP bbd) "
from (null):0

Note that it defaults to 'equals any' so handles multiple values well--you'd expect if you pass it
Two values, you'd get back two
>> TestAR.hash_to_conditions_string 'test_column_name equals' => ['abc', 'bbd']
=> " ( BINARY  test_ars.test_column_name = abc OR  BINARY  test_ars.test_column_name = bbd) "
>> TestAR.hash_to_conditions_string 'test_column_name equals all' => ['abc', 'bbd']
RuntimeError: unsupported style for _all, as it would seem exclusive so to not make sense
>> TestAR.hash_to_conditions_string 'test_column_name doesnt equal any' => ['abc', 'bbd']
=> " BINARY  test_ars.test_column_name = abc AND  BINARY  test_ars.test_column_name = bbd"
>> TestAR.hash_to_conditions_string 'test_column_name equals all' => ['abc', 'bbd']
RuntimeError: unsupported style for _all, as it would seem exclusive so to not make sense
>> TestAR.hash_to_conditions_string 'test_column_name not any' => [3,4]
=> "NOT  BINARY  test_ars.test_column_name = 3 AND NOT  BINARY  test_ars.test_column_name = 4"
>> TestAR.hash_to_conditions_string 'test_column_name is included in' => [3,4]
=> " (  BINARY  test_ars.test_column_name LIKE %3% OR   BINARY  test_ars.test_column_name LIKE %4%) "
=end
  # basically converts an english hash to a string
# ltodo rename
  def self.hash_to_conditions_string(hash)
    hash.keys.collect{|key| 
      if hash[key].class == Array
        attribute, negativity, is_case_sensitive, condition, optional_multiples_style = split_attribute_and_condition(key) # grab the multiples style
	condition ||= :equals
  # so our options are
  # matches, starts with, in, equals [in and equals are same]
	unless optional_multiples_style
	  case condition
	  when :equals, :starts_with, :ends_with, :matches
		optional_multiples_style = :any
          else # includes, gt
		optional_multiples_style = :all
	  end
        end
        
        if negativity
	    optional_multiples_style = optional_multiples_style == :all ? :any : :all
        end
	
        interiors = hash[key].map{|sub_key| 
          build_single_condition(key, sub_key)
        }
        
        if optional_multiples_style == :all
          raise 'unsupported style for multiples, as it would seem exclusive so to be mutually exclusive--not make sense' if [:equals, :starts_with, :begins_with, :ends_with].include? condition unless negativity

          interiors.join(" AND ")
        else # :any  Note that we use 'OR' instead of IN (a,b,c) since it's the equivalent, really, and then we don't have to worry about special cases, like a REGEX or what not.
          # we should never raise if we get here, since we're only widening the scope
          
      			' (' << interiors.join(" OR ") << ') '
        end
        
      else
        build_single_condition(key, hash[key])
      end
    }.join(" AND ")
  end
  # todo: allow for it to come in as a string or a symbol
  # could do: make it work with :conditions => {} ??

  # ltodo some day nested hashes [?]
  def self.build_single_condition(key, argument)
    attribute, negativity, is_case_insensitive, condition, optional_multiples_style = split_attribute_and_condition(key)
    # TODO pass out multiples as nil so we can tweak it, here.  equals defaults to 'any', includes default to 'all'
 
    unless column_names.include? attribute
      # allow for them to pass in an attribute
      if argument.class.ancestors.include?(ActiveRecord::Base) and self.column_names.include?(attribute + '_id') and argument.class != Array # last one to double check if they pass somethign like :order => user.orders, which we don't handle yet
        # assume they are trying to use a shortcut :order => order_instance and really want its id
        # could do -- :order => instance check if the class matches expected  
        attribute += '_id'
        argument = argument.id
      elsif column_names.include?(attribute.gsub(' ', '_')) # test if replacing spaces with _'s fixes it, to allow for natural queries
        attribute = attribute.gsub(' ', '_')
      end
      raise 'unknown DB column -- possible syntax error' + attribute unless self.column_names.include? attribute
    end

   negativity_contribution = ''
   if negativity
	negativity_contribution = 'NOT '
   end
   condition ||= :equals 
    fragment = case condition
      when :greater_than then ["> ?", argument]
      when :less_than then ["< ?", argument]
      when :gte then [">= ?", argument]
      when :lte then ["<= ?", argument]
      when :begins_with then ["LIKE ?", "#{argument}%"]
      when :ends_with then ["LIKE ?", "%#{argument}"]
      when :contains then ["LIKE ?", "%#{argument}%"]
      when :matches then 
	argument = argument.inspect[1..-2] if argument.class == Regexp
	["REGEXP ?", argument.gsub(')', '\\)').gsub(')', '\\)')]# TODO sanitize better
      when :equals then [attribute_condition(argument), argument] # ignores work with nil (!) TOTEST
      else raise 'unknown condition' + condition.to_s
    end
    # ltodo if it's an integer don't do binary compare [?]:)
    case_sensitive_addition = ' BINARY ' unless is_case_insensitive
    
    "#{negativity_contribution}#{case_sensitive_addition} #{table_name}.#{connection.quote_column_name(attribute)} #{sanitize_sql(fragment)}"
  end

  # TODO does it actually work with pre-existing conditions?
  def self.where conditions, options = {} # I guess the original author overcame this by just sanitizing sql on its way down or something (?) this need help TODO decide on scope of this :)
    if options[:conditions] and options[:conditions].class == Hash
	size = conditions.length
	conditions.merge! options[:conditions]
        options[:conditions] = nil # assume we'll handle them all
    end
    new_conditions = self.hash_to_conditions_string(conditions)
    if options[:conditions]
	raise 'weird conditions type' + options[:conditions].class.to_s = ' expected String'  unless options[:conditions].class == String
        options[:conditions] = "(#{options[:conditions]}) AND (new_conditions)"
    else
      options[:conditions] = new_conditions
    end
    options[:limit] ||= 2
    all = self.find :all, options
    print "MORE THAN ONE EXISTED!" if all.length > 1
    all[0]
  end
  
  def self.awhere conditions, options = {}
    new_conditions = self.hash_to_conditions_string(conditions)
    options[:conditions] ||= ''
    options[:conditions] = ' ' << new_conditions
    self.find :all, options
  end
  
=begin
#doctest should split a name+condition into column_name, case_sensitivity, condition, multiples_style
>> TestAR.build_single_condition('test_column_name equals',3)
=> "  BINARY  test_ars.test_column_name = 3"
>> ActiveRecord::Base.split_attribute_and_condition('name_includes')
=> ["name", nil, nil, :contains, nil]
>> ActiveRecord::Base.split_attribute_and_condition 'email_address icontains'
=> ["email_address", nil, :insensitive, :contains, nil]
>> ActiveRecord::Base.split_attribute_and_condition 'email_address icontains all'
=> ["email_address", nil, :insensitive, :contains, :all]
>> ActiveRecord::Base.split_attribute_and_condition 'email_address contains all'
=> ["email_address", nil, nil, :contains, :all]
>> ActiveRecord::Base.split_attribute_and_condition 'email_address contains any'
=> ["email_address", nil, nil, :contains, :any]
>> ActiveRecord::Base.split_attribute_and_condition 'email_address equals'
=> ["email_address", nil, nil, :equals, nil]
>> ActiveRecord::Base.split_attribute_and_condition 'email_address =>'
=> ["email_address", nil, nil, :equals, nil]
>> ActiveRecord::Base.split_attribute_and_condition 'email_address ='
=> ["email_address", nil, nil, :equals, nil]
>> ActiveRecord::Base.split_attribute_and_condition 'email_address == '
=> ["email_address", nil, nil, :equals, nil]
>> ActiveRecord::Base.split_attribute_and_condition 'email_address case insensitive == '
=> ["email_address", nil, :insensitive, :equals, nil]
>> ActiveRecord::Base.split_attribute_and_condition 'email_address case insensitive !gt '
=> ["email_address", :not, :insensitive, :greater_than, nil]
>> ActiveRecord::Base.split_attribute_and_condition 'email_address case insensitive !gt'
=> ["email_address", :not, :insensitive, :greater_than, nil]
>> ActiveRecord::Base.split_attribute_and_condition 'email_address !='
=> ["email_address", :not, nil, :equals, nil]
>> ActiveRecord::Base.split_attribute_and_condition 'email_address matches'
=> ["email_address", nil, nil, :matches, nil]
>> ActiveRecord::Base.split_attribute_and_condition 'email_address doesnt match'
=> ["email_address", :not, nil, :matches, nil]
>> ActiveRecord::Base.split_attribute_and_condition 'email_address doesnt match any'
=> ["email_address", :not, nil, :matches, :any]
>> ActiveRecord::Base.split_attribute_and_condition 'email address include'
=> ["email address", nil, nil, :contains, nil]
>> ActiveRecord::Base.split_attribute_and_condition 'email address matches'
=> ["email address", nil, nil, :matches, nil]
>> ActiveRecord::Base.split_attribute_and_condition 'email address within'
=> ["email address", nil, nil, nil, :any]
=end
  #returns column name, is_it_negative? is_it_case_insensitive?
  def self.split_attribute_and_condition(key) 
    # also allows for _any and _all and _in suffixes (_in being _any) TOTEST
    # also allows for an ending ? like :includes? => 'abc' TOTEST
    # also allows for an s prefix, i.e. _sstarts_with => 'ABC'  TOTEST
    # TODO allow for anything to have 'not' at the beginning (?) or doesnt? -- not yet TOTEST
    # ltodo could have 'matches case insensitive' =>
    # todo have an opening ! ok '!includes' =>
    # ltodo less than stuffs -- does equal to or something fit?
    column_name = key.to_s.sub(/(| |__|_)(|i|insensitive|case[ _]insensitive)(| |_)(?:is||is[ _]included)(?:| |_)(|doesnt|does[ _]not|not|not|!)(|_| )(|gt|greater[_ ]than|less[ _]than|lt|equals?|equal to|lte|gte|starts[ _]with|begins[ _]with|ends?[ _]with|end[ _]with|contains?|includes?|included|matches|match|matchs|=|==|=>|<|<=|>|>=)(|_| )(|any|all|in|within)(|\?)(| )$/, "")
    # TEST is included, is included in
#dbg
    # found within
    insensitivity = $2
    negativity = $4
    condition = $6
    multiples_style =  $8
    # this is slightly bifurcated
    insensitivity = insensitivity.blank? ? nil : insensitivity.gsub(' ', '_').to_sym
    negativity = negativity.blank? ? nil : negativity.gsub(' ', '_').to_sym
    condition = condition.blank? ? nil : condition.gsub(' ', '_').to_sym
    # multiples are words already, no gsub necessary
    multiples_style = multiples_style.blank? ? nil : multiples_style.to_sym
    
    # ltodo fix included is included in
    # seems to be a difference between first name is included in => ['bob, 'fred'] and first name include
    # should be able to ignore spaces after this point
    normalize = {:in => :any, :included => :contains, :include => :contains, :includes => :contains, :case_insensitive => :insensitive, :lt => :less_than, :"<="  => :lte, :equal => :equals, :contain => :contains, :match => :matches, :matchs => :matches, :"!" => :not, :doesnt => :not, :does_not => :not, :"=" => :equals, :"==" => :equals, :"=>" => :equals, :within => :any, :i => :insensitive, :is_not => :not, :end_with => :ends_with, :"<" => :less_than, :"<=" => :lte, :">" => :greater_than, :">=" => :gte, :gt => :greater_than, :starts_with => :begins_with}
    #pp 'thus far', insensitivity, negativity, condition, multiples_style
    insensitivity = normalize[insensitivity] if normalize[insensitivity]
    negativity = normalize[negativity] if normalize[negativity]
    condition = normalize[condition] if normalize[condition]
    multiples_style = normalize[multiples_style] if normalize[multiples_style]
    #pp 'now have', insensitivity, negativity, condition, multiples_style

    return column_name, negativity, insensitivity, condition, multiples_style
  end
end
# todo does doesnt_start_with_all work? it should err, I think TOTEST
