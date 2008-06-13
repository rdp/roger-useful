# This file shows an example of a TCP connector ['web server']
# that uses interleaved fibers to accomplish
# non blocking DB access in a friendly way.
# to test it in action 
# ab -n 5 -c 5 http://127.0.0.1:10000/

require 'rubygems'
require 'eventmachine'
require '../source/asymy/asymy'
require 'pp'

class ConnectionPool
  def initialize count, opts
    @pool = []
    @waiting = []
    count.times { @pool << Asymy::Connection.new(opts) }
  end

  def check_if_can_run
	if @pool.length > 0 and @waiting.length > 0
		conn = @pool.shift
		query, block = @waiting.shift
		conn.exec(query) {|*args|
                        block.call *args
			@pool << conn
                        check_if_can_run # seems to work with a large pool--we'll call it good
                }
#		check_if_can_run # not sure if this is necessary ever or not...
	end
  end 

  def exec_when_available query, &block
	@waiting << [query, block]
	check_if_can_run
  end
end


module DoOneSql
  @@count_ever = 0

  def post_init
     @@count_ever += 1
     @my_count = @@count_ever
     print 'got incoming', @my_count, 'starting fiber'
     @conn = Asymy::Connection.new $opts
    @running_fiber = Fiber.new {
     if rand(2) == 1
	go :big
     else
	go :small
	go :small
	go :small
	go :big
	go :small
	go :small
     end
     }
    @running_fiber.resume # blocks 'pausing all the way' like jerking movements forward, as mysql queries come back and it resumed
  end

  def go size
	print "fiber start #{size}"
	case size
	when :big
		db = 'user_sessions'
	else
		db = 'users'
	end
	query  =  "select count(*) from #{db}"
	block = lambda { |i, c|
		print "done #{size} #{@my_count}\n"
  	}

	a = @conn.exec_and_fiber_yield(query, &block)
	print "done a #{@my_count}\n"
	b = @conn.exec_and_fiber_yield(query, &block)
	print "done b #{@my_count}\n"
	c = @conn.exec_and_fiber_yield(query, &block)
	print "done c #{@my_count}\n"
	@conn.em_connection.close_connection
	self.close_connection

  end

end

EventMachine::run {
   $opts = {:target => "localhost",
                             :port => 3306,
                             :username => "wilkboar_ties",
                             :password => "ties",
                             :database => "local_leadgen_dev"}
  
  EM.start_server "0.0.0.0", 10000, DoOneSql
   
} # EM run
