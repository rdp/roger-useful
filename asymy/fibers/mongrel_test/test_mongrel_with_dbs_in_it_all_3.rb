require 'rubygems'

require 'mongrel'
style = [:fibered, :threaded, :evented][0]
require 'swiftcore/evented_mongrel' if [:evented, :fibered].include? style
require '../../source/asymy/asymy' if style == :fibered
require '../setup_db_opts'

 class SimpleHandler < Mongrel::HttpHandler
    @@count_ever = 0
    def process(request, response)
      # note that @'s here are shared among mongrel's incoming connections!--don't use them
      my_count = @@count_ever
      @@count_ever += 1
      response.start(200) do |head,out|
	print  " in head\n"
        head["Content-Type"] = "text/plain"
        out.write("hello!\n")

	conn = Asymy::Connection.new $opts if style == :fibered
	conn
	5.times { |n|
	   local_var = nil # an example of how to set local vars :)
	   size = [:big, :small][my_count % 2]
	   query = "select count(*) from #{ size == :small ? 'users' : 'user_sessions' }"
	   print "starting #{my_count} #{size} #{n}\n"
           if style == :fibered
		a = conn.exec_and_fiber_yield(query) {|h, c| local_var = [h,c]} # a == local_var
	   end
           print "done #{my_count} #{size} #{n}\n"
	}
	conn.em_connection.close_connection

      end
    end
 end

 h = Mongrel::HttpServer.new("0.0.0.0", 3000)
 h.register("/", SimpleHandler.new)
 h.register("/files", Mongrel::DirHandler.new("."))
 h.run.join
