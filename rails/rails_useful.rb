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

