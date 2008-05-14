# note for this to work you'll want to patch your rails so you don't get Expected X got Y
# ltodo: patch here
# ltodo: track each file and its time, case two are updated simultaneously
# ltodo: restart whole thing on certain files changing
# ltodo: reload multiple changed files

def dbg; require 'ruby-debug'; debugger; end
class Object
 def e &block
  self.each &block
 end
end

generic_patches = File.dirname(__FILE__) + '/rails_generic.rb'
require generic_patches if File.exist?(generic_patches)

if (ENV['RAILS_ENV'] == 'production' or ENV['RAILS_ENV'] == 'staging') and Socket.gethostname =~ /Rogers/ # ruby does it itself otherwise, I think.  There may be a rails way to do this.
watcher_thread = Thread.new{
print 'STARTING WATCHER'
latest_inserted = Time.now
reload_dirs = ['app/controllers', 'app/schools', 'app/models']
death_dirs = ['app/helpers', 'config']
loop do
 for dir in death_dirs do
	for file in (Dir.glob dir + '/*') + (Dir.glob dir + '/*/*')
		time = File.ctime file
		if time > latest_inserted
			print 'got new' , file, "\n KILLING\n"
  			system("kill -9 #{Process.pid}") # we are done
		end
	end
 end

 has_new = false
 for dir in reload_dirs
	for file in (Dir.glob dir + '/*') + (Dir.glob dir + '/*/*')
  
		time = File.ctime file
		if time > latest_inserted
			has_new = true
			print 'got new' , file, "\n"
			break
		end
	end
	break if has_new
  end
 if has_new
   #   file === app/controllers/flexpro_controller.rb
  if file[-3..-1] =='.rb'
    filename_only = File.basename(file)[0..-4]
    begin
      Object.send(:remove_const, filename_only.camelize) # wants only the string--hangs on object :)
    rescue Exception => e
	    pp 'ack got a remove error' + filename_only + e.to_s
    end

    begin
	    load file 
    rescue Exception => e
	    pp 'ack got load error! app currently in unstable state!' + e.to_s, e.backtrace
            system("kill -9 #{Process.pid}") # we are done
    end
    print "successfully reloaded\n"
  end
   
  latest_inserted = Time.now
 end
 sleep 0.2
 end
}
end
