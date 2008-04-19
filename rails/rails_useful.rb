#require File.dirname(__FILE__) + '/slice3.rb'

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
   #   file === app/controllers/flexpro_controller.rb
  if file[-3..-1] =='.rb'
    filename_only = File.basename(file)[0..-4]
    constant_name = filename_only.camelize.constantize
    Object.send(:remove_const, filename_only.camelize) # wants only the string--hangs on object :)
    load file # reload it
  end
   
  #system("kill -9 #{Process.pid}") # we are done
  latest_inserted = Time.now
 end
 sleep 0.2
 end
}
end
