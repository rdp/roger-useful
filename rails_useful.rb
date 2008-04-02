require File.dirname(__FILE__) + '/slice2.rb'

def dbg; require 'ruby-debug'; debugger; end
if (ENV['RAILS_ENV'] == 'production' or ENV['RAILS_ENV'] == 'staging') and Socket.gethostname == "Rogers-little-PowerBook.local" # ruby does it itself otherwise, I think.  There may be a rails way to do this.
watcher_thread = Thread.new{
print 'STARTING WATCHER'
latest_inserted = Time.now
dirs = ['app/controllers', 'app/schools', 'app/models', 'vendor/plugins/substruct', 'app/helpers']
loop do
 has_new = false

 for dir in dirs
	for file in (Dir.glob dir + '/*') + (Dir.glob dir + '/*/*')
		time = File.ctime file
		if time > latest_inserted
			has_new = true
			print 'got new' , file
			break
		end
	end
	break if has_new
  end
 if has_new
  system("kill -9 #{Process.pid}") # we are done
  latest_inserted = Time.now
 end
 sleep 0.2
 end
}
end

  
# some rails optimizations, from http://blog.pluron.com/2008/01/ruby-on-rails-i.html
module Benchmark
    def realtime
        r0 = Time.now
        yield
        r1 = Time.now
        r1.to_f - r0.to_f
    end
    module_function :realtime
end

class BigDecimal
    alias_method :eq_without_boolean_comparison, :==
    def eq_with_boolean_comparison(other)
        return false if [FalseClass, TrueClass].include? other.class
        eq_without_boolean_comparison(other)
    end
    alias_method :==, :eq_with_boolean_comparison
end


# Alters ActiveRecord's condition handling to allow conditions specified as a hash
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
class ActiveRecord::Base
# todo: check if it works with custom foreign keys
  def self.hash_to_conditions_string(hash)
      hash.keys.collect{|key| 
	if hash[key].class == Array
		attribute, is_case_sensitive, condition, optional_multiples_style = split_attribute_and_condition(key) # grab its multiples style
		interiors = hash[key].map{|sub_key| 
			build_single_condition(key, sub_key)
		}
		if condition.to_s =~ /doesnt/
			optional_multiples_style = optional_multiples_style == :all ? :any : :all # negate it, to keep the logic right for negatives
		end
		
		if optional_multiples_style == :all
			raise 'unsupported style for _all, as it would seem exclusive so to not make sense' if [:gt, :less_than, :lt, :is, :equals, :lte, :gte, :starts_with, :begins_with, :ends_with].include? condition
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
  def self.build_single_condition(key, argument)
    attribute, is_case_sensitive, condition, optional_multiples_style = split_attribute_and_condition(key)

    if argument.class.ancestors.include? ActiveRecord::Base and self.column_names.include? (attribute + '_id') and argument.class != Array # last one to double check if they pass somethign like :order => user.orders, which we don't handle yet
	# assume they are trying to use a shortcut :order => order_instance and really want its id
	# could do -- :order => instance check if the class matches expected  
	attribute += '_id'
	argument = argument.id
    end
    raise 'unknown column -- possible syntax error' + attribute unless self.column_names.include? attribute
   
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
  def self.split_attribute_and_condition(key) 
  # also allows for _any and _all and _in suffixes (_in being _any)
  # also allows for an ending ? like :includes? => 'abc'
  # also allows for an s prefix, i.e. _sstarts_with => 'ABC'  # for case sensitive
  # TODO allow for anything to have 'not' at the beginning (?) or doesnt? -- not yet
    return [key.to_s.sub(/(_|__)(|s)(|gt|greater_than|less_than|lt|is|equals|lte|gte|starts_with|begins_with|ends_with|doesnt_start_with|doesnt_end_with|contains|include.|doesnt_contain|matches)(|_|__)(|any|all|in)(|\?)$/, ""), ($2 and !$2.blank?) ? :cs : nil, ($3 and !$3.blank?) ? $3.to_sym : :equals, !$5.blank? ? $5.to_sym : nil]
  end
end

# todo does doesnt_start_with_all work? it should err, I think

class ActiveRecord::Base
  class << self
    alias :fw :find_where
    alias :aw :all_where
  end
end

